SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_GetVIPCouponsByShop]    
    @enterpriseId NVARCHAR(50), -- 企業號Id    
    @memberNo NVARCHAR(50) = NULL,     -- 會員No    
    @ShopId NVARCHAR(50)        -- 門市Id    
AS    

-- DECLARE @enterpriseId NVARCHAR(50) = 'xurf', -- 企業號Id    
--     @memberNo NVARCHAR(50) = '0903008556',     -- 會員No    
--     @ShopId NVARCHAR(50) = 'A001'        -- 門市Id      
   
BEGIN    
    SET NOCOUNT ON;    
          
    /* 
    SELECT DISTINCT     
	    a.TicketInfoID AS CouponId,    
	    d.PicUrl AS ImagePath,    
	    d.TicketTypeName AS CouponName,   
        CASE d.TicketFlag     
            WHEN 1 THEN '現金券'    
            WHEN 2 THEN '商品抵用券'    
            WHEN 3 THEN '商品折扣券'    
            WHEN 4 THEN '現金折扣券'    
            WHEN 5 THEN '整單折扣券'    
            WHEN 6 THEN '運費折讓券'    
            WHEN 7 THEN '商品兌換券'    
            ELSE '未知類型'   
	    END AS TicketType,    
		NULL AS BeginDate,    
	    b.EndDate,    
	    a.TicketExpiredDate, --優惠券到期日    
	    NULL AS TradeTime,    
	    1 AS Count,    
		0 AS Status,  
        '每次消費限用1張' AS UsageLimit,  
        d.TicketDiscount,  
        d.TicketPrice,  
        d.ValidType,  
        d.ValidDays,  
        d.ExpiredDate,  
        ISNULL(TRF.FoodList, '全部商品') AS AllowedFoods,  
        ISNULL(TRS.ShopList, '全部門店') AS AllowedShops,  
        FORMAT(b.BeginTime, 'HH:mm') AS BeginTime,  
        FORMAT(b.EndTime, 'HH:mm') AS EndTime,  
        FORMAT(b.BeginDate, 'yyyy-MM-dd') AS BeginDate,  
        FORMAT(b.EndDate, 'yyyy-MM-dd') AS EndDate,  
        b.Week1,  
        b.Week2,  
        b.Week3,  
        b.Week4,  
        b.Week5,  
        b.Week6,  
        b.Week7,  
        b.Remark  
	FROM VIP_TicketInfo a    
	LEFT JOIN VIP_TradeRules b     
	    ON a.EnterPriseID = b.EnterPriseID     
	    AND a.TradeRuleCode = b.TradeRuleCode    
	LEFT JOIN VIP_Trade_Ticket c    
	    ON a.EnterPriseID = c.EnterPriseID    
	    AND a.TicketInfoID = c.TicketInfoID    
	LEFT JOIN VIP_TicketType d    
	    ON a.EnterPriseID = d.EnterPriseID     
	    AND a.TicketTypeCode = d.TicketTypeCode    
    LEFT JOIN (  
        SELECT TradeRuleCode,    
               STRING_AGG(ShopName, ', ') AS ShopList   
        FROM VIP_TradeRuleShops   
        WHERE EnterPriseID = @EnterpriseID   
        GROUP BY TradeRuleCode   
    ) AS TRS ON b.TradeRuleCode = TRS.TradeRuleCode   
    LEFT JOIN (  
        SELECT TradeRuleCode,    
               STRING_AGG(FoodName, ', ') AS FoodList   
        FROM VIP_TradeRules_Food   
        WHERE EnterPriseID = @EnterpriseID   
        GROUP BY TradeRuleCode   
    ) AS TRF ON b.TradeRuleCode = TRF.TradeRuleCode  
	WHERE a.MemberNO = @MemberNo    
	AND a.EnterPriseID = @EnterPriseID    
	AND a.TicketCount > 0    
	AND c.ShopID = @ShopID    
	AND (    
	    b.EndDate IS NULL     
	    OR CONCAT(b.EndDate, ' ', CONVERT(VARCHAR, b.EndTime, 114)) >= GETDATE()    
	)    
        
    UNION ALL    
        
	SELECT DISTINCT    
	    a.TicketInfoID AS CouponId,    
	    c.PicUrl AS ImagePath,    
	    c.TicketTypeName AS CouponName,    
        CASE c.TicketFlag     
            WHEN 1 THEN '現金券'    
            WHEN 2 THEN '商品抵用券'    
            WHEN 3 THEN '商品折扣券'    
            WHEN 4 THEN '現金折扣券'    
            WHEN 5 THEN '整單折扣券'    
            WHEN 6 THEN '運費折讓券'    
            WHEN 7 THEN '商品兌換券'    
            ELSE '未知類型'   
	    END AS TicketType,    
	    b.BeginDate,	--開始日期    
		b.EndDate,		--結束日期    
		a.TicketExpiredDate, --優惠券到期日    
		NULL AS TradeTime,    
		1 AS Count,    
		1 AS Status,  
        '每次消費限用1張' AS UsageLimit,  
        c.TicketDiscount,  
        c.TicketPrice,  
        c.ValidType,  
        c.ValidDays,  
        c.ExpiredDate,  
        ISNULL(TRF.FoodList, '全部商品') AS AllowedFoods,  
        ISNULL(TRS.ShopList, '全部門店') AS AllowedShops,  
        FORMAT(b.BeginTime, 'HH:mm') AS BeginTime,  
        FORMAT(b.EndTime, 'HH:mm') AS EndTime,  
        FORMAT(b.BeginDate, 'yyyy-MM-dd') AS BeginDate,  
        FORMAT(b.EndDate, 'yyyy-MM-dd') AS EndDate,  
        b.Week1,  
        b.Week2,  
        b.Week3,  
        b.Week4,  
        b.Week5,  
        b.Week6,  
        b.Week7,  
        b.Remark  
	FROM VIP_TicketInfo a    
	LEFT JOIN VIP_TradeRules b     
	    ON a.EnterPriseID = b.EnterPriseID     
	    AND a.TradeRuleCode = b.TradeRuleCode    
	LEFT JOIN VIP_TicketType c     
	    ON a.EnterPriseID = c.EnterPriseID     
	    AND a.TicketTypeCode = c.TicketTypeCode    
	LEFT JOIN VIP_Trade_Ticket d     
	    ON a.EnterPriseID = d.EnterPriseID     
	    AND a.TicketInfoID = d.TicketInfoID    
    LEFT JOIN (  
        SELECT TradeRuleCode,    
               STRING_AGG(ShopName, ', ') AS ShopList   
        FROM VIP_TradeRuleShops   
        WHERE EnterPriseID = @EnterpriseID   
        GROUP BY TradeRuleCode   
    ) AS TRS ON b.TradeRuleCode = TRS.TradeRuleCode   
    LEFT JOIN (  
        SELECT TradeRuleCode,    
               STRING_AGG(FoodName, ', ') AS FoodList   
        FROM VIP_TradeRules_Food   
        WHERE EnterPriseID = @EnterpriseID   
        GROUP BY TradeRuleCode   
    ) AS TRF ON b.TradeRuleCode = TRF.TradeRuleCode  
	WHERE a.EnterPriseID = @EnterPriseID    
	  AND a.MemberNO = @MemberNo    
	  AND a.TicketCount > 0    
	  AND d.ShopID = @ShopID  -- 限制優惠券適用的門店    
	  AND (b.BeginDate IS NOT NULL     
	       AND CONCAT(b.BeginDate, ' ', CONVERT(VARCHAR, b.BeginTime, 114)) > GETDATE())    
	    
	UNION ALL    
	    
	SELECT     
	    a.TicketInfoID AS CouponId,    
	    b.PicUrl AS ImagePath,     
	    b.TicketTypeName AS CouponName,    
        CASE b.TicketFlag     
            WHEN 1 THEN '現金券'    
            WHEN 2 THEN '商品抵用券'    
            WHEN 3 THEN '商品折扣券'    
            WHEN 4 THEN '現金折扣券'    
            WHEN 5 THEN '整單折扣券'    
            WHEN 6 THEN '運費折讓券'    
            WHEN 7 THEN '商品兌換券'    
            ELSE '未知類型'   
	    END AS TicketType,      
		NULL AS BeginDate,       -- 有效期限(起)    
		NULL AS EndDate,       -- 有效期限(迄)    
		c.TicketExpiredDate, --優惠券到期日    
	    a.TradeTime, --轉贈日期     
		1 AS Count,                    -- 張數    
		2 AS Status, -- 優惠券狀態 0:可使用,1:未生效,2:已轉贈  
        '每次消費限用1張' AS UsageLimit,  
        b.TicketDiscount,  
        b.TicketPrice,  
        b.ValidType,  
        b.ValidDays,  
        b.ExpiredDate,  
        ISNULL(TRF.FoodList, '全部商品') AS AllowedFoods,  
        ISNULL(TRS.ShopList, '全部門店') AS AllowedShops,  
        NULL AS BeginTime,  
        NULL AS EndTime,  
        NULL AS BeginDate,  
        NULL AS EndDate,  
        NULL AS Week1,  
        NULL AS Week2,  
        NULL AS Week3,  
        NULL AS Week4,  
        NULL AS Week5,  
        NULL AS Week6,  
        NULL AS Week7,  
        NULL AS Remark  
	FROM VIP_Trade_Ticket a    
	LEFT JOIN VIP_TicketInfo c     
	    ON a.EnterPriseID = c.EnterPriseID     
	    AND c.TIfrom_GID = a.TicketInfoID    
	INNER JOIN Vip_TicketType b     
	    ON a.TicketTypeCode = b.TicketTypeCode     
	    AND a.EnterPriseID = b.EnterPriseID    
    LEFT JOIN (  
        SELECT TradeRuleCode,    
               STRING_AGG(ShopName, ', ') AS ShopList   
        FROM VIP_TradeRuleShops   
        WHERE EnterPriseID = @EnterpriseID   
        GROUP BY TradeRuleCode   
    ) AS TRS ON c.TradeRuleCode = TRS.TradeRuleCode   
    LEFT JOIN (  
        SELECT TradeRuleCode,    
               STRING_AGG(FoodName, ', ') AS FoodList   
        FROM VIP_TradeRules_Food   
        WHERE EnterPriseID = @EnterpriseID   
        GROUP BY TradeRuleCode   
    ) AS TRF ON c.TradeRuleCode = TRF.TradeRuleCode  
	WHERE a.TradeTypeCode = '11'  -- 轉贈類型    
	AND a.EnterPriseID = @EnterPriseID    
	AND a.MemberNO = @MemberNo    
	AND a.ShopID = @ShopID;  -- 加入門店條件    
    */ 
 
    -- 250703 noa調整 
    SELECT DISTINCT  
        vti.GID ,  
		vti.TicketInfoID AS CouponId, 
        vtt.PicUrl AS ImagePath, 
        vtt.TicketTypeName AS CouponName,
        vtt.TicketTypeCode,
        CASE vtt.TicketFlag     
            WHEN 1 THEN '現金券'    
            WHEN 2 THEN '商品抵用券'    
            WHEN 3 THEN '商品折扣券'    
            WHEN 4 THEN '現金折扣券'    
            WHEN 5 THEN '整單折扣券'    
            WHEN 6 THEN '運費折讓券'    
            WHEN 7 THEN '商品兌換券'    
            ELSE '未知類型'   
	    END AS TicketType,  
        vtr.BeginDate, 
        vtr.EndDate, 
        iif(vtt.ValidType='2','9999-12-31',vti.TicketExpiredDate) TicketExpiredDate, 
        vti.GenTradetime AS TradeTime, 
        vti.TicketCount [Count], 
        0 AS [status], --要改狀態區別 
        IIF(vtr.BeginDate is not NULL AND (CAST(vtr.BeginDate AS DATETIME) + CAST(CAST(vtr.BeginTime AS TIME) AS DATETIME)) > GETDATE(),1,iif(vtr.TradeTypeCode='11',2,0)), 
        '每次消費限用1張' AS UsageLimit,  -- 有需要這個東西嗎 
        vtt.TicketDiscount, 
        vtt.TicketPrice, 
        vtt.ValidType, 
        vtt.ValidDays, 
        vtt.ExpiredDate, 
        IIF(vtt.TicketFlag=1,'全部商品',ISNULL(TRF.FoodList, '無適用商品')) AS AllowedFoods,  
        ISNULL(TRS.ShopList, '全部門店') AS AllowedShops,  
        CAST(vtr.BeginDate AS DATETIME) + CAST(CAST(vtr.BeginTime AS TIME) AS DATETIME) BeginTime, 
        CAST(vtr.EndDate AS DATETIME) + CAST(CAST(vtr.EndTime AS TIME) AS DATETIME) EndTime, 
        vtr.Week1, 
        vtr.Week2, 
        vtr.Week3, 
        vtr.Week4, 
        vtr.Week5, 
        vtr.Week6, 
        vtr.Week7, 
        vtr.Remark 
	FROM VIP_TicketInfo vti -- 券資訊 
	JOIN VIP_TicketType vtt -- 券類別 
		ON vti.EnterPriseID = vtt.EnterPriseID 
		AND vti.TicketTypeCode = vtt.TicketTypeCode 
	JOIN VIP_TradeRules vtr -- 交易規則 
		ON vti.TicketTypeCode = vtr.CardTypeCode 
		AND vti.EnterPriseID = vtr.EnterPriseID 
	LEFT JOIN VIP_TradeRuleShops vtrs -- 交易規則門店 
		ON vtr.EnterPriseID = vtrs.EnterPriseID 
		AND vtr.TradeRuleCode = vtrs.TradeRuleCode 
	LEFT JOIN S_Organ so -- 組織機構 
		ON vtrs.EnterPriseID = so.EnterPriseID 
		AND vtrs.ShopID = so.OrgCode 
    LEFT JOIN (  
        SELECT TradeRuleCode,    
               STRING_AGG(CAST(ShopName AS NVARCHAR(MAX)), ', ') AS ShopList   
        FROM VIP_TradeRuleShops   
        WHERE EnterPriseID = @enterpriseId   
        GROUP BY TradeRuleCode   
    ) AS TRS ON vtr.TradeRuleCode = TRS.TradeRuleCode   
    LEFT JOIN (  
        SELECT TradeRuleCode,    
               STRING_AGG(CAST(FoodName AS NVARCHAR(MAX)), ', ') AS FoodList   
        FROM VIP_TradeRules_Food   
        WHERE EnterPriseID = @enterpriseId   
        GROUP BY TradeRuleCode   
    ) AS TRF ON vtr.TradeRuleCode = TRF.TradeRuleCode  
	WHERE vti.EnterPriseID = @enterpriseId 
	AND vti.MemberNO = @memberNo 
	AND ISNULL(vtrs.ShopID, '') <> '9999' -- 過濾會員註冊店 
	AND (CONVERT(VARCHAR, vti.TicketExpiredDate, 112) >= CONVERT(VARCHAR, GETDATE(), 112) 
	OR vtt.ValidType = '2') -- 未過期或是永久有效 
	AND vti.TicketCount > 0 
    AND isnull(vtrs.ShopID,'allShops')=@ShopId 
    ORDER BY vtt.TicketTypeName,iif(vtt.ValidType='2','9999-12-31',vti.TicketExpiredDate) 
    
END
GO
