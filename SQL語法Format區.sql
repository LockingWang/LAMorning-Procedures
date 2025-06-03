CREATE PROCEDURE [dbo].[sp_GetVIPCouponsByShop] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @memberNo NVARCHAR(50),     -- 會員No 
    @ShopId NVARCHAR(50)        -- 門市Id 
AS 
BEGIN 
    SET NOCOUNT ON; 
         
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
	    b.BeginDate,	--開始日期 
		b.EndDate,		--結束日期 
		NULL AS TradeTime, 
		1 AS Count, 
		1 AS Status 
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
	    b.TicketTypeName AS CouponName, 
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