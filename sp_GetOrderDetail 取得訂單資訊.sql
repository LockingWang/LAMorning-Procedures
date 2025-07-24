CREATE OR ALTER PROCEDURE [dbo].[sp_GetOrderDetail]    
	@EnterPriseID NVARCHAR(50),    
	@ShopID NVARCHAR(50),    
    @memberNo NVARCHAR(50) = NULL,  -- 會員No     
    @langId NVARCHAR(10) = NULL,  -- 語系Id     
    @orderId NVARCHAR(50)   -- 訂單Id     
AS     
 
-- DECLARE @EnterPriseID NVARCHAR(50) = 'xurf',    
-- 	@ShopID NVARCHAR(50) = 'A002',    
--     @memberNo NVARCHAR(50) = '0903008556',  -- 會員No     
--     @langId NVARCHAR(10) = 'TW',  -- 語系Id     
--     @orderId NVARCHAR(50) = '7c4d846e-b4da-4dcb-8a20-f5bf8a556cde'   -- 訂單Id   
    
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
				o.*     
			FROM P_OrdersTemp_Web o    
			WHERE     
				o.EnterPriseID = @EnterPriseID AND         
				o.ID = @orderId    
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES   
		) AS [order],    
		(    
			SELECT     
				i.*,   
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
		) AS shopInfo  
END 