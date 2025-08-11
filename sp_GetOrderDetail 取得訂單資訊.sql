SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_GetOrderDetail]     
	@EnterPriseID NVARCHAR(50),     
	@ShopID NVARCHAR(50),     
    @memberNo NVARCHAR(50) = NULL,  -- 會員No      
    @langId NVARCHAR(10) = NULL,  -- 語系Id      
    @orderId NVARCHAR(50)   -- 訂單Id      
AS  
  
-- DECLARE @EnterPriseID NVARCHAR(50) = '90367984',     
--  	@ShopID NVARCHAR(50) = 'A01',     
--     @memberNo NVARCHAR(50) = '0930158924',  -- 會員No      
--     @langId NVARCHAR(10) = 'TW',  -- 語系Id      
--     @orderId NVARCHAR(50) = 'ad336e5e-201f-4b88-9b8a-a0cc519e1978'   -- 訂單Id    
     
BEGIN      
	SET NOCOUNT ON;     
     
	-- 參數驗證     
	IF @EnterPriseID IS NULL OR @ShopID IS NULL OR @orderId IS NULL     
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
                i.MainID,
                i.KindID,
                i.Parent,
                i.[Add],
                i.Count,
                i.Price,
                i.AddCost,
                i.Total,
                i.FoodName,
                i.Taste,
                i.OrderIndex,
				(    
					SELECT TOP 1 Dir    
					FROM S_UploadFile uf     
					WHERE uf.itemid = i.FoodID AND uf.enterpriseid = @EnterPriseID     
				) AS imagePath    
			FROM P_ItemsTemp_Web i     
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
        (     
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
		) AS coupons
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
                i.MainID,
                i.KindID,
                i.Parent,
                i.[Add],
                i.Count,
                i.Price,
                i.AddCost,
                i.Total,
                i.FoodName,
                i.Taste,
                i.OrderIndex,
				(    
					SELECT TOP 1 Dir    
					FROM S_UploadFile uf     
					WHERE uf.itemid = i.FoodID AND uf.enterpriseid = @EnterPriseID     
				) AS imagePath    
			FROM P_Items i     
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
		) AS coupons
        ) a where [order] is not null -- 避免線上訂單無資料，導致前端無法正常顯示
END 
GO
