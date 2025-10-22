SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_GetOrderDetail2]     
	@EnterPriseID NVARCHAR(50),     
	@ShopID NVARCHAR(50),     
    @memberNo NVARCHAR(50) = NULL,  -- 會員No      
    @langId NVARCHAR(10) = 'TW',  -- 語系Id      
    @orderId NVARCHAR(50)   -- 訂單Id      
AS  
  
-- DECLARE @EnterPriseID NVARCHAR(50) = 'xurf',     
--  	@ShopID NVARCHAR(50) = 'A001',     
--     @memberNo NVARCHAR(50) = '',  -- 會員No      
--     @langId NVARCHAR(10) = 'JP',  -- 語系Id      
--     @orderId NVARCHAR(50) = 'da7e8ec5-18cd-4df3-b0f3-311c9301de5a'   -- 訂單Id    
     
BEGIN      
	SET NOCOUNT ON;     
     
	-- 參數驗證     
	IF @EnterPriseID IS NULL /*OR @ShopID IS NULL*/ OR @orderId IS NULL     -- 因為直接進會員專區不會帶入門店，所以不會有門店參數
	BEGIN     
		RAISERROR(N'缺少必要參數：EnterpriseID、ShopID 或 orderId 不能為空', 16, 1)     
		RETURN     
	END     
     
    select * from (
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
                o.LastModify,
                o.VIPTel,
                o.AgioDiscount,
                o.CardID,
                o.OrderStatus,
                o.OrderFoodCount,
                o.OrderNo2,
                o.PayStatus,
                o.VipAddr,
                o.OrderType,
                o.AppFunGID,
                o.ReceiverName,
                o.ReceiverMark,
                o.TakeWayTime,
                o.firmServiceFee,
                o.deliverFee,
                o.packageFee,
                o.PayChannel,
                o.BillType,
                o.TakeWayTime2,
                o.PrintStatus,
                o.VipAddrHead
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
			FROM P_AgioTemp_Web coupon   
			WHERE      
				coupon.EnterPriseID = @EnterPriseID AND          
				coupon.orderID = @orderId     
			FOR JSON PATH, INCLUDE_NULL_VALUES    
		),'[]') AS coupons
    UNION
    --POS訂單紀錄用
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
                o.LastModify,
                o.VIPTel,
                o.AgioDiscount,
                o.CardID,
                CASE WHEN right(o.ID,1)='#' THEN 52 ELSE o.OrderStatus END OrderStatus,
                o.[Count],
                o.OrderNo,
                o.PayStatus,
                '' VipAddr,
                o.OrderType,
                '' AppFunGID,
                o.ReceiverName,
                o.ReceiverMark,
                o.CloseTime TakeWayTime,
                0 firmServiceFee,
                0 deliverFee,
                0 packageFee,
                '' PayChannel,
                o.BillType,
                o.CloseTime TakeWayTime2,
                1 PrintStatus,
                '' VipAddrHead 
			FROM P_Orders o     
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
        ISNULL (
        (     
			SELECT      
				coupon.ItemID AS targetItemID,
                coupon.ReasonName AS couponName,
                CASE
                    WHEN coupon.AgioTotal > 0 THEN coupon.AgioTotal
                    WHEN coupon.AgioCost > 0 THEN coupon.AgioCost
                    ELSE 0
                END AS agioPrice
			FROM P_Agio coupon   
			WHERE      
				coupon.EnterPriseID = @EnterPriseID AND          
				coupon.orderID = @orderId     
			FOR JSON PATH, INCLUDE_NULL_VALUES    
		),'[]') AS coupons
        ) a where [order] is not null -- 避免線上訂單無資料，導致前端無法正常顯示
END 
GO
