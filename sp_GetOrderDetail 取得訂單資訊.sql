CREATE OR ALTER PROCEDURE [dbo].[sp_GetOrderDetail]     
	@EnterPriseID NVARCHAR(50),     
	@ShopID NVARCHAR(50),     
    @memberNo NVARCHAR(50) = NULL,  -- 會員No      
    @langId NVARCHAR(10) = NULL,  -- 語系Id      
    @orderId NVARCHAR(50)   -- 訂單Id      
AS  
  
-- DECLARE @EnterPriseID NVARCHAR(50) = 'XFlamorning',     
-- 	@ShopID NVARCHAR(50) = 'A999',     
--     @memberNo NVARCHAR(50) = '0903008556',  -- 會員No      
--     @langId NVARCHAR(10) = 'TW',  -- 語系Id      
--     @orderId NVARCHAR(50) = 'dc8b9978-d515-4c11-a3f4-939f91ae79a1'   -- 訂單Id    
     
BEGIN      
	SET NOCOUNT ON;     
     
	-- 參數驗證     
	IF @EnterPriseID IS NULL OR @ShopID IS NULL OR @orderId IS NULL     
	BEGIN     
		RAISERROR(N'缺少必要參數：EnterpriseID、ShopID 或 orderId 不能為空', 16, 1)     
		RETURN     
	END     
     
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
                ISNULL(AgioTotal, coupon.AgioCost) AS agioPrice
			FROM P_AgioTemp_Web coupon   
			WHERE      
				coupon.EnterPriseID = @EnterPriseID AND          
				coupon.orderID = @orderId     
			FOR JSON PATH, INCLUDE_NULL_VALUES    
		) AS coupons
END 