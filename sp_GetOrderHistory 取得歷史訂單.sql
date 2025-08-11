SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_GetOrderHistory] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @memberNo NVARCHAR(50),       -- 會員No 
    @dateFilterStart DATETIME = NULL,   -- 日期選擇(起) 
	@dateFilterEnd DATETIME = NULL   -- 日期選擇(迄) 
AS 

--  DECLARE @enterpriseId NVARCHAR(50) = '90367984', -- 企業號Id 
--  @memberNo NVARCHAR(50) = '0930158924',       -- 會員No 
--  @dateFilterStart DATETIME = NULL,   -- 日期選擇(起) 
--  @dateFilterEnd DATETIME = NULL   -- 日期選擇(迄) 

BEGIN 
    SET NOCOUNT ON; 

    -- Pos歷史訂單
    WITH OrderData AS (
        SELECT  
            o.ID AS orderId, 
            s.OrgName AS shopName, 
            o.OrderNo AS orderNumber, 
            o.SaleTime AS orderTime, 
            o.CloseTime,
            o.[Count] AS itemCount, 
            o.PayTotal AS totalAmount,
            o.OrderStatus AS [status],
            o.PayStatus AS PayStatus,
            o.SaleType AS orderType,
            -- 移除 # 符號的原始 orderId
            CASE 
                WHEN o.ID LIKE '%#%' THEN LEFT(o.ID, CHARINDEX('#', o.ID) - 1)
                ELSE o.ID 
            END AS originalOrderId,
            -- 標記是否為退貨記錄
            CASE 
                WHEN o.ID LIKE '%#%' THEN 1
                ELSE 0 
            END AS isReturn,
            -- 排序優先級：退貨記錄優先，然後按時間排序
            ROW_NUMBER() OVER (
                PARTITION BY 
                    CASE 
                        WHEN o.ID LIKE '%#%' THEN LEFT(o.ID, CHARINDEX('#', o.ID) - 1)
                        ELSE o.ID 
                    END
                ORDER BY 
                    CASE 
                        WHEN o.ID LIKE '%#%' THEN 1
                        ELSE 0 
                    END DESC,  -- 退貨記錄優先
                    o.SaleTime DESC  -- 時間降序
            ) AS rn
        FROM P_Orders o 
        JOIN S_Organ s 
            ON o.EnterpriseID = s.EnterPriseID 
           AND o.ShopID = s.OrgCode 
        WHERE o.EnterpriseID = @enterpriseId 
        AND o.VIPNo = @memberNo 
        AND (@dateFilterStart IS NULL OR o.SaleTime >= @dateFilterStart) 
        AND (@dateFilterEnd IS NULL OR o.SaleTime < DATEADD(DAY, 1, @dateFilterEnd)) 
        AND ISNULL(o.OrderType,0) <> 2
    )
         
    SELECT  
	    o.ID AS orderId, 
	    s.OrgName AS shopName, 
	    o.OrderNo2 AS orderNumber, 
	    o.SaleTime AS orderTime, 
	    o.OrderFoodCount AS itemCount, 
	    o.PayTotal AS totalAmount, 
	    o.OrderStatus AS [status],
        o.PayStatus AS PayStatus,
	    o.SaleType AS orderType 
	FROM P_OrdersTemp_Web o 
	JOIN S_Organ s 
	    ON o.EnterpriseID = s.EnterPriseID 
	   AND o.ShopID = s.OrgCode 
	WHERE o.EnterpriseID = @enterpriseId 
	AND o.VIPNo = @memberNo 
    AND (@dateFilterStart IS NULL OR o.SaleTime >= @dateFilterStart) 
	AND (@dateFilterEnd IS NULL OR o.SaleTime < DATEADD(DAY, 1, @dateFilterEnd)) 
    UNION
    SELECT 
        orderId, 
        shopName, 
        orderNumber, 
        CASE WHEN isReturn = 1 THEN CloseTime ELSE orderTime END, -- 作廢抓作廢的時間
        CASE WHEN isReturn = 1 THEN itemCount * -1 ELSE itemCount END, -- 負項資料轉正
        CASE WHEN isReturn = 1 THEN totalAmount * -1 ELSE totalAmount END, -- 負項資料轉正
        CASE WHEN isReturn = 1 THEN 52 ELSE [status] END, -- pos作廢為null，轉換為52供前端判斷
        PayStatus,
        CASE WHEN orderType = 'forhere' THEN 'scaneDesk'
            WHEN orderType in ('togo','pickup') THEN 'takeout'
            WHEN orderType in ('delivery','other') THEN orderType
        END
    FROM OrderData 
    WHERE rn = 1  -- 只取每個訂單的第一筆記錄
    ORDER BY orderTime DESC;
	
END
GO
