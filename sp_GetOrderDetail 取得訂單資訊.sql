CREATE OR ALTER PROCEDURE [dbo].[sp_GetOrderDetail] 
	@EnterPriseID NVARCHAR(50), 
	@ShopID NVARCHAR(50), 
    @memberNo NVARCHAR(50),  -- 會員No  
    @langId NVARCHAR(10) = NULL,  -- 語系Id  
    @orderId NVARCHAR(50)   -- 訂單Id  
AS  
 
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
				o.ShopID = @ShopID AND  
				o.OrderNo2 = @orderId 
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
		) AS [order], 
		( 
			SELECT  
				i.*,
				(
					SELECT TOP 1 Dir
					FROM S_UploadFile uf 
					WHERE uf.itemid = i.FoodID AND uf.enterpriseid = @EnterPriseID 
				) AS ImagePath
			FROM P_ItemsTemp_Web i 
			INNER JOIN P_OrdersTemp_Web o ON  
				i.EnterPriseID = o.EnterPriseID AND  
				i.ShopID = o.ShopID AND  
				i.OrderID = o.ID 
			WHERE  
				o.EnterPriseID = @EnterPriseID AND  
				o.ShopID = @ShopID AND  
				o.OrderNo2 = @orderId 
			FOR JSON PATH, INCLUDE_NULL_VALUES
		) AS items 
END 