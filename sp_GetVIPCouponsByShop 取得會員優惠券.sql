CREATE PROCEDURE [dbo].[sp_GetVIPCouponsByShop] 
    @enterpriseId NVARCHAR(50), -- 企業號Id
    @memberNo NVARCHAR(50),     -- 會員No
    @ShopId NVARCHAR(50)        -- 門市Id
AS 
BEGIN 
    SET NOCOUNT ON; 
--     
--    SELECT 
--        'AA' AS CouponId,                -- 優惠券Id 
--        'https://s3-alpha-sig.figma.com/img/69fd/4448/62df446a1aca3aea13cf561ece5d1233?Expires=1743379200&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=TA6lI2ff5E3f34rfXC9H~YCQqs~BOAdc48VLjV~oiIVHHQhsQXswX-LsEf8K9np~XAEKnqzsyoILdt69CEAx3hf1D9ZmbldPB4LKOQIwBg4U6Ge0FeAy5-jC5shAeGf6XRhEKBiEgLFENXfgQvM~j0ORwrMtcv0-zZCQe5rBCBpHIGi9Jl15jL33ovQK7RAuW6EYXPyaRr4oM-8W23YrJcpCrjj27uP-V2ITGIPTdfLxBUcNgiKVi7EXVLuz7k480Eo2NYVaM1HDJKmBZkvjayL5hxfalI50iCRcwOdhSnD-5V~5btg-xdYxdi~M~km5p-x6AiYN5-vDkwvWICwTPg__' AS ImagePath,
               -- 優惠券照片路徑 
--        '折扣券' AS CouponName,              -- 優惠券名稱 
--        GETDATE() AS BeginDate,       -- 有效期限(起) 
--        GETDATE() AS EndDate,       -- 有效期限(迄) 
--        GETDATE() AS TradeTime,     -- 轉贈日期 
--        1 AS Count,                    -- 張數 
--        0 AS Status -- 優惠券狀態 0:可使用,1:未生效,2:已轉贈 
         
    SELECT DISTINCT  
	    a.TicketInfoID AS CouponId, 
	    d.PicUrl AS ImagePath, 
	    d.TicketTypeName AS CouponName, 
		NULL AS BeginDate, 
	    b.EndDate, 
	    NULL AS TradeTime, 
	    1 AS Count, 
		0 AS Status 
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
	    --a.TradeRuleCode, 
	    --ISNULL(c.TicketTypeName, b.TradeRuleName) AS TicketTypeName, 
	    --b.Week1, b.Week2, b.Week3, b.Week4, b.Week5, b.Week6, b.Week7, 
	    --b.BeginTime,	--開始時間 
	    --b.EndTime,		--結束時間 
	    b.BeginDate,	--開始日期 
		b.EndDate,		--結束日期 
		NULL AS TradeTime, 
		1 AS Count, 
		1 AS Status 
	--    (SELECT TWCaption FROM SC_Dictionary  
	--     WHERE [Table] = 'VIP_Rela' AND ENCaption =  
	--        CASE  
	--            WHEN ISNULL(c.TicketFlag, '0') = '1' THEN 'TicketFlag1'  
	--            WHEN ISNULL(c.TicketFlag, '0') = '2' THEN 'TicketFlag2'  
	--            WHEN ISNULL(c.TicketFlag, '0') = '3' THEN 'TicketFlag3'  
	--            WHEN ISNULL(c.TicketFlag, '0') = '4' THEN 'TicketFlag4'  
	--        END) AS [type], 
	--    (SELECT STUFF((SELECT ',' + CONVERT(VARCHAR, ShopName)  
	--        FROM VIP_TradeRuleShops  
	--        WHERE EnterPriseID = @EnterPriseID AND TradeRuleCode = a.TradeRuleCode  
	--        FOR XML PATH('')), 1, 1, '')) AS shops, 
	--    a.TicketCount 
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
	--    b.TicketFlag, 
	    b.TicketTypeName AS CouponName, 
	--    b.TicketTypeNameEn, 
	--    c.CardID AS ToCardID   
		NULL AS BeginDate,       -- 有效期限(起) 
		NULL AS EndDate,       -- 有效期限(迄) 
	    a.TradeTime, --轉贈日期  
		1 AS Count,                    -- 張數 
		2 AS Status -- 優惠券狀態 0:可使用,1:未生效,2:已轉贈 
	FROM VIP_Trade_Ticket a 
	LEFT JOIN VIP_TicketInfo c  
	    ON a.EnterPriseID = c.EnterPriseID  
	    AND c.TIfrom_GID = a.TicketInfoID 
	INNER JOIN Vip_TicketType b  
	    ON a.TicketTypeCode = b.TicketTypeCode  
	    AND a.EnterPriseID = b.EnterPriseID 
	WHERE a.TradeTypeCode = '11'  -- 轉贈類型 
	AND a.EnterPriseID = @EnterPriseID 
	AND a.MemberNO = @MemberNo 
	AND a.ShopID = @ShopID;  -- 加入門店條件 
 
END