CREATE OR ALTER PROCEDURE [dbo].[sp_GetCouponInfo] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @couponId NVARCHAR(50)    -- 優惠券代碼 
AS 
BEGIN 
    SET NOCOUNT ON; 
     
	SELECT  
	    CASE TT.TicketFlag  
	        WHEN 1 THEN '現金券' 
	        WHEN 2 THEN '商品抵用券' 
	        WHEN 3 THEN '商品折扣券' 
	        WHEN 4 THEN '現金折扣' 
	        WHEN 5 THEN '整單折扣券' 
	        WHEN 6 THEN '運費折讓券' 
	        WHEN 7 THEN '商品兌換券' 
	        ELSE '未知類型' 
	    END AS TicketType, 
	 
	    '每次消費限用1張' AS UsageLimit, 
	 
	    -- 優惠券基本資訊 
	    TI.TicketInfoID, 
	    TT.TicketDiscount, 
	    TT.TicketPrice, 
	    TT.ValidType, 
	    TT.ValidDays, 
	    TT.ExpiredDate, 
	    TI.TicketExpiredDate, 
	 
	    -- 限制使用 
	    ISNULL(TRF.FoodList, '全部商品') AS AllowedFoods, 
	    ISNULL(TRS.ShopList, '全部門店') AS AllowedShops, 
	 
	    -- 適用時間 
	    FORMAT(TR.BeginTime, 'HH:mm') AS BeginTime, 
	    FORMAT(TR.EndTime, 'HH:mm') AS EndTime, 
	    FORMAT(TR.BeginDate, 'yyyy-MM-dd') AS BeginDate, 
	    FORMAT(TR.EndDate, 'yyyy-MM-dd') AS EndDate, 
	    TR.Week1, 
	    TR.Week2, 
	    TR.Week3, 
	    TR.Week4, 
	    TR.Week5, 
	    TR.Week6, 
	    TR.Week7, 
	 
	    -- 備註 
	    TR.Remark 
	 
	FROM VIP_TradeRules AS TR 
	LEFT JOIN Vip_TicketType AS TT 
	    ON TR.CardTypeCode = TT.TicketTypeCode  
	    AND TT.NeedRule = 1 
	    AND TT.EnterpriseID = @EnterpriseID 
	LEFT JOIN VIP_TicketInfo AS TI 
	    ON TT.EnterPriseID = TI.EnterPriseID  
	    AND TT.TicketTypeCode = TI.TicketTypeCode 
	LEFT JOIN ( 
	    SELECT TradeRuleCode,  
	           STRING_AGG(ShopName, ', ') AS ShopList 
	    FROM VIP_TradeRuleShops 
	    WHERE EnterPriseID = @EnterpriseID 
	    GROUP BY TradeRuleCode 
	) AS TRS ON TR.TradeRuleCode = TRS.TradeRuleCode 
	LEFT JOIN ( 
	    SELECT TradeRuleCode,  
	           STRING_AGG(FoodName, ', ') AS FoodList 
	    FROM VIP_TradeRules_Food 
	    WHERE EnterPriseID = @EnterpriseID 
	    GROUP BY TradeRuleCode 
	) AS TRF ON TR.TradeRuleCode = TRF.TradeRuleCode 
	WHERE  
	    TR.EnterPriseID = @EnterpriseID  
	    AND TR.TradeTypeCode = 'T2' 
	    AND TI.TicketInfoID = @couponId; 
 
END