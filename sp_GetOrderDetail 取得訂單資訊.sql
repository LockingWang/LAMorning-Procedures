SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_GetOrderDetail]     
	@EnterPriseID NVARCHAR(50),   -- 企業號          
    @langId NVARCHAR(10) = 'TW',  -- 語系
    @orderId NVARCHAR(50)         -- 訂單ID      
AS  
  
-- DECLARE 
--     @EnterPriseID NVARCHAR(50) = 'XFlamorning',      
--     @langId NVARCHAR(10) = 'TW',
--     @orderId NVARCHAR(50) = '25588fe0-5462-44c7-9e2a-e53e9d09d157'
     
BEGIN      
	SET NOCOUNT ON;     
     
	-- 參數驗證     
	IF @EnterPriseID IS NULL OR @orderId IS NULL
	BEGIN     
		RAISERROR(N'缺少必要參數：EnterpriseID 或 orderId 不能為空', 16, 1)     
		RETURN     
	END     
     
	-- 判斷訂單來源
	DECLARE @outputOrder NVARCHAR(10);
	DECLARE @hasOnlineOrder BIT = 0;
	DECLARE @hasPosOrder BIT = 0;
	
	-- 檢查線上訂單
	IF EXISTS (SELECT 1 FROM P_OrdersTemp_Web WHERE EnterPriseID = @EnterPriseID AND ID = @orderId)
	BEGIN
		SET @hasOnlineOrder = 1;
	END
	
	-- 檢查POS訂單
	IF EXISTS (SELECT 1 FROM P_Orders WHERE EnterPriseID = @EnterPriseID AND ID = @orderId)
	BEGIN
		SET @hasPosOrder = 1;
	END
	
	-- 決定訂單來源：兩者都有值時優先使用 POS
	IF @hasPosOrder = 1
	BEGIN
		SET @outputOrder = 'pos';
	END
	ELSE IF @hasOnlineOrder = 1
	BEGIN
		SET @outputOrder = 'online';
	END
	ELSE
	BEGIN
		-- 兩者都沒有資料，回傳空結果
		SELECT 
			NULL AS [order],
			NULL AS items,
			NULL AS shopInfo,
			'[]' AS coupons;
		RETURN;
	END
	
	-- 根據 outputOrder 決定資料來源
	IF @outputOrder = 'online'
	BEGIN
		-- 線上訂單：使用 P_OrdersTemp_Web、P_ItemsTemp_Web
		SELECT     
			(     
				SELECT      
					o.ID,
					o.DeskID,
					o.SaleTime,
					o.AgioPercent,
					o.AgioTotal,
					o.AgioCost,
					o.Total,
					o.PayTotal,
					o.ServiceTotal,
					o.ServicePercent,
					o.VIPType,
					o.VIPNo,
					o.VIPName,
					o.SaleType,
					o.VIPTel,
					o.AgioDiscount,
					o.CardID,
					o.OrderStatus,
					o.OrderFoodCount,
					o.OrderNo2,
					o.PayStatus,
					o.VipAddr,
					o.OrderType,
					o.ReceiverName,
					o.ReceiverMark,
					o.TakeWayTime,
					o.firmServiceFee,
					o.deliverFee,
					o.packageFee,
					o.PayChannel,
					o.BillType,
					o.TakeWayTime2
				FROM P_OrdersTemp_Web o     
				WHERE      
					o.EnterPriseID = @EnterPriseID AND          
					o.ID = @orderId     
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES    
			) AS [order],     
			(     
				SELECT      
					i.ID,
					i.FoodID,
					ISNULL(i.MainID,'') MainID,
					i.KindID,
					i.Parent,
					-- 多語系處理 i.[Add] 欄位
					CASE 
						WHEN i.[Add] IS NULL OR i.[Add] = '' THEN i.[Add]
						ELSE (
							SELECT STRING_AGG(t.translatedItem, ',')
							FROM (
								SELECT DISTINCT 
									CASE 
										WHEN LANGADD.Content IS NOT NULL THEN 
											JSON_VALUE(LANGADD.Content, '$.' + @langId + '.Name') +
											CASE 
												WHEN CHARINDEX('x', splitItems.addItem) > 0 
												THEN SUBSTRING(splitItems.addItem, CHARINDEX('x', splitItems.addItem), LEN(splitItems.addItem))
												ELSE '' 
											END
										ELSE splitItems.addItem
									END AS translatedItem
								FROM (
									-- 拆解加料清單，例如「霜降牛,香菇x2,黑輪」
									SELECT TRIM(value) AS addItem
									FROM STRING_SPLIT(i.[Add], ',')
								) splitItems
								LEFT JOIN (
									-- 先 DISTINCT 避免同名加料多筆
									SELECT DISTINCT EnterpriseID, Name, ID, [Owner]
									FROM P_FoodAdd
								) FA ON FA.EnterpriseID = @EnterPriseID 
									AND FA.Name = TRIM(SUBSTRING(splitItems.addItem, 1, 
										CASE 
											WHEN CHARINDEX('x', splitItems.addItem) > 0 
											THEN CHARINDEX('x', splitItems.addItem) - 1 
											ELSE LEN(splitItems.addItem) 
										END))
									AND FA.[Owner] IS NULL
								LEFT JOIN (
									-- 語系表防重 + 限定語系 JSON 存在
									SELECT DISTINCT EnterpriseID, SourceID, TableName, Content
									FROM P_Data_Language_D
									WHERE JSON_VALUE(Content, '$.' + @langId + '.Name') IS NOT NULL
								) LANGADD ON LANGADD.EnterpriseID = @EnterPriseID 
									AND LANGADD.SourceID = FA.ID
									AND LANGADD.TableName = 'FoodAdd'
							) t
						)
					END AS [Add],
					i.Count,
					i.Price,
					i.AddCost,
					i.Total,
					ISNULL(JSON_VALUE(LANGFOOD.Content, '$.' + @langId + '.Name'), i.FoodName) AS FoodName,
					i.Taste,
					i.OrderIndex,
					(    
						SELECT TOP 1 Dir    
						FROM S_UploadFile uf     
						WHERE uf.itemid = i.FoodID AND uf.enterpriseid = @EnterPriseID     
					) AS imagePath    
				FROM P_ItemsTemp_Web i
				LEFT JOIN P_Data_Language_D LANGFOOD      
					ON LANGFOOD.EnterpriseID = @enterpriseid      
					AND LANGFOOD.SourceID = i.FoodID      
					AND LANGFOOD.TableName = 'Food'         
				INNER JOIN P_OrdersTemp_Web o ON      
					i.EnterPriseID = o.EnterPriseID AND          
					i.OrderID = o.ID     
				WHERE      
					o.EnterPriseID = @EnterPriseID AND          
					o.ID = @orderId     
				FOR JSON PATH, INCLUDE_NULL_VALUES    
			) AS items,   
			(   
				SELECT    
					o.EnterPriseID,   
					o.OrgCode AS ShopID,   
					o.OrgName AS ShopName,   
					o.Tel AS ShopTel,   
					o.Addr AS ShopAddress   
				FROM S_Organ o  
				JOIN P_OrdersTemp_Web orders ON orders.ID = @orderId  
				WHERE o.EnterPriseID = @EnterPriseID AND o.OrgCode = orders.ShopID  
				FOR JSON PATH, INCLUDE_NULL_VALUES   
			) AS shopInfo,
			ISNULL((     
				SELECT      
					coupon.ItemID AS targetItemID,
					coupon.ReasonName AS couponName,
					CASE
						WHEN coupon.AgioTotal > 0 THEN coupon.AgioTotal
						WHEN coupon.AgioCost > 0 THEN coupon.AgioCost
						ELSE 0
					END AS agioPrice
				FROM (
					SELECT ItemID, ReasonName, AgioTotal, AgioCost
					FROM P_AgioTemp_Web
					WHERE EnterPriseID = @EnterPriseID AND orderID = @orderId
					UNION ALL
					SELECT ItemID, ReasonName, AgioTotal, AgioCost
					FROM P_Agio
					WHERE EnterPriseID = @EnterPriseID AND orderID = @orderId
				) coupon
				FOR JSON PATH, INCLUDE_NULL_VALUES    
			),'[]') AS coupons;
	END
	ELSE -- @outputOrder = 'pos'
	BEGIN
		-- POS訂單：使用 P_Orders、P_Items
		SELECT     
			(     
				SELECT      
					o.ID,
					o.DeskID,
					o.SaleTime,
					o.AgioPercent,
					o.AgioTotal,
					o.AgioCost,
					o.Total,
					o.PayTotal,
					o.ServiceTotal,
					o.ServicePercent,
					o.VIPType,
					o.VIPNo,
					o.VIPName,
					o.SaleType,
					o.VIPTel,
					o.AgioDiscount,
					o.CardID,
					CASE WHEN right(o.ID,1)='#' THEN 52 ELSE o.OrderStatus END OrderStatus,
					o.[Count],
					o.OrderNo,
                    ISNULL(otw.OrderNo2, '') AS OrderNo2, -- 提供線上單號給前端
					CASE WHEN o.Checkout = 1 THEN '1' ELSE '0' END AS PayStatus,
					'' VipAddr,
					o.OrderType,
					o.ReceiverName,
					o.ReceiverMark,
					o.CloseTime TakeWayTime,
					0 firmServiceFee,
					0 deliverFee,
					0 packageFee,
					pch.Kind AS PayChannel,
					o.BillType,
					o.CloseTime TakeWayTime2
				FROM P_Orders o     
                LEFT JOIN P_OrdersTemp_Web otw ON 
					otw.EnterPriseID = @EnterPriseID AND 
					otw.ID = @orderId
                LEFT JOIN P_Checks pch ON 
					pch.EnterPriseID = @EnterPriseID AND 
					pch.OrderID = @orderId
				WHERE      
					o.EnterPriseID = @EnterPriseID AND          
					o.ID = @orderId        
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES    
			) AS [order],     
			(     
				SELECT      
					i.ID,
					i.FoodID,
					ISNULL(i.MainID,'') MainID,
					i.KindID,
					i.Parent,
					-- 多語系處理 i.[Add] 欄位
					CASE 
						WHEN i.[Add] IS NULL OR i.[Add] = '' THEN i.[Add]
						ELSE (
							SELECT STRING_AGG(
								CASE 
									WHEN LANGADD.Content IS NOT NULL THEN 
										JSON_VALUE(LANGADD.Content, '$.' + @langId + '.Name') + 
										SUBSTRING(addItem, 
											CASE 
												WHEN CHARINDEX('x', addItem) > 0 
												THEN CHARINDEX('x', addItem) 
												ELSE LEN(addItem) + 1 
											END, 
											LEN(addItem))
									ELSE addItem
								END, 
								','
							)
							FROM (
								SELECT TRIM(value) as addItem
								FROM STRING_SPLIT(i.[Add], ',')
							) splitItems
							LEFT JOIN P_FoodAdd FA ON FA.EnterpriseID = @EnterPriseID 
								AND FA.Name = TRIM(SUBSTRING(splitItems.addItem, 1, 
									CASE 
										WHEN CHARINDEX('x', splitItems.addItem) > 0 
										THEN CHARINDEX('x', splitItems.addItem) - 1 
										ELSE LEN(splitItems.addItem) 
									END))
								AND FA.[Owner] IS NULL
							LEFT JOIN P_Data_Language_D LANGADD ON LANGADD.EnterpriseID = @EnterPriseID 
								AND LANGADD.SourceID = FA.ID 
								AND LANGADD.TableName = 'FoodAdd'
						)
					END AS [Add],
					i.Count,
					i.Price,
					i.AddCost,
					i.Total,
					ISNULL(JSON_VALUE(LANGFOOD.Content, '$.' + @langId + '.Name'), i.FoodName) AS FoodName,
					i.Taste,
					i.OrderIndex,
					(    
						SELECT TOP 1 Dir    
						FROM S_UploadFile uf     
						WHERE uf.itemid = i.FoodID AND uf.enterpriseid = @EnterPriseID     
					) AS imagePath    
				FROM P_Items i     
				LEFT JOIN P_Data_Language_D LANGFOOD      
					ON LANGFOOD.EnterpriseID = @enterpriseid      
					AND LANGFOOD.SourceID = i.FoodID      
					AND LANGFOOD.TableName = 'Food'         
				INNER JOIN P_Orders o ON      
					i.EnterPriseID = o.EnterPriseID AND          
					i.OrderID = o.ID     
				WHERE      
					o.EnterPriseID = @EnterPriseID AND          
					o.ID = @orderId     
				FOR JSON PATH, INCLUDE_NULL_VALUES    
			) AS items,   
			(   
				SELECT    
					o.EnterPriseID,   
					o.OrgCode AS ShopID,   
					o.OrgName AS ShopName,   
					o.Tel AS ShopTel,   
					o.Addr AS ShopAddress   
				FROM S_Organ o  
				JOIN P_Orders orders ON orders.ID = @orderId  
				WHERE o.EnterPriseID = @EnterPriseID AND o.OrgCode = orders.ShopID  
				FOR JSON PATH, INCLUDE_NULL_VALUES   
			) AS shopInfo,
			ISNULL((     
				SELECT      
					coupon.ItemID AS targetItemID,
					coupon.ReasonName AS couponName,
					CASE
						WHEN coupon.AgioTotal > 0 THEN coupon.AgioTotal
						WHEN coupon.AgioCost > 0 THEN coupon.AgioCost
						ELSE 0
					END AS agioPrice
				FROM (
					SELECT ItemID, ReasonName, AgioTotal, AgioCost
					FROM P_AgioTemp_Web
					WHERE EnterPriseID = @EnterPriseID AND orderID = @orderId
					UNION ALL
					SELECT ItemID, ReasonName, AgioTotal, AgioCost
					FROM P_Agio
					WHERE EnterPriseID = @EnterPriseID AND orderID = @orderId
				) coupon
				FOR JSON PATH, INCLUDE_NULL_VALUES    
			),'[]') AS coupons;
	END
END 
GO
