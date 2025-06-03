CREATE PROCEDURE [dbo].[sp_GetCouponInfo] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @couponId NVARCHAR(50)    -- 優惠券代碼 
AS 
BEGIN 
    SET NOCOUNT ON; 
     
--    SELECT 
--        '券別' AS Title,        -- 標題 
--        '商品抵用券' AS Content     -- 內容 
     
    WITH FormattedData AS ( 
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
	        END AS TicketFlagDescription, 
	        '每次消費限用1張' AS Restriction, 
	        ISNULL(TRF.FoodList, '全部商品') AS FoodList, 
	        ISNULL(TRS.ShopList, '全部門店') AS ShopList, 
	        CONCAT( 
	            FORMAT(TR.BeginDate, 'yyyy-MM-dd'), ' - ', FORMAT(TR.EndDate, 'yyyy-MM-dd'),  
	            ' [ ',  
	            CASE WHEN  
	                CAST(TR.Week1 AS INT) + CAST(TR.Week2 AS INT) + CAST(TR.Week3 AS INT) +  
	                CAST(TR.Week4 AS INT) + CAST(TR.Week5 AS INT) + CAST(TR.Week6 AS INT) +  
	                CAST(TR.Week7 AS INT) = 7  
	            THEN '每天'  
	            ELSE  
	                STUFF( 
	                    CASE WHEN TR.Week1 = 1 THEN ', 星期一' ELSE '' END + 
	                    CASE WHEN TR.Week2 = 1 THEN ', 星期二' ELSE '' END + 
	                    CASE WHEN TR.Week3 = 1 THEN ', 星期三' ELSE '' END + 
	                    CASE WHEN TR.Week4 = 1 THEN ', 星期四' ELSE '' END + 
	                    CASE WHEN TR.Week5 = 1 THEN ', 星期五' ELSE '' END + 
	                    CASE WHEN TR.Week6 = 1 THEN ', 星期六' ELSE '' END + 
	                    CASE WHEN TR.Week7 = 1 THEN ', 星期天' ELSE '' END 
	                , 1, 2, '') -- 移除開頭的逗號和空格 
	            END, 
	            ' ]' 
	        ) AS ValidityPeriod, 
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
	        AND TI.TicketInfoID = @CouponId 
	) 
	SELECT  
	    '["券別", "限制", "限制使用商品", "適用門店", "適用時間", "備註"]' AS Title, 
	    ( 
	        SELECT  
	            TicketFlagDescription, Restriction, FoodList, ShopList, ValidityPeriod, Remark 
	        FROM FormattedData 
	        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER 
	    ) AS Content; 
END