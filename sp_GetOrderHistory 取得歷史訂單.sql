CREATE PROCEDURE [dbo].[sp_GetOrderHistory] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @memberNo NVARCHAR(50),       -- 會員No 
    @dateFilterStart DATETIME = NULL,   -- 日期選擇(起) 
	@dateFilterEnd DATETIME = NULL   -- 日期選擇(迄) 
AS 

-- DECLARE @enterpriseId NVARCHAR(50) = 'XFlamorning', -- 企業號Id 
-- @memberNo NVARCHAR(50) = '0900123123',       -- 會員No 
-- @dateFilterStart DATETIME = NULL,   -- 日期選擇(起) 
-- @dateFilterEnd DATETIME = NULL   -- 日期選擇(迄) 

BEGIN 
    SET NOCOUNT ON; 
         
    SELECT  
	    o.ID AS orderId, 
	    s.OrgName AS shopName, 
	    o.OrderNo2 AS orderNumber, 
	    o.SaleTime AS orderTime, 
	    o.OrderFoodCount AS itemCount, 
	    o.Total AS totalAmount, 
	    o.PayStatus AS status, 
	    o.SaleType AS orderType 
	FROM P_OrdersTemp_Web o 
	JOIN S_Organ s 
	    ON o.EnterpriseID = s.EnterPriseID 
	   AND o.ShopID = s.OrgCode 
	WHERE o.EnterpriseID = @enterpriseId 
	AND o.VIPNo = @memberNo 
    AND (@dateFilterStart IS NULL OR o.SaleTime >= @dateFilterStart) 
	AND (@dateFilterEnd IS NULL OR o.SaleTime < DATEADD(DAY, 1, @dateFilterEnd)) 
END