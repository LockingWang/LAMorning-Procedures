SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 修改預存程序以正確顯示券的有效期間
ALTER PROCEDURE [dbo].[sp_GetRedeemableCoupons] 
@enterpriseId NVARCHAR(50), -- 企業號Id    
@memberNo NVARCHAR(50), -- 會員No
@shopId NVARCHAR(50) -- 門市Id
AS

--declare 
--@enterpriseId NVARCHAR(50) = 'xurf', -- 企業號Id    
--@memberNo NVARCHAR(50) = '0988681451', -- 會員No
--@shopId NVARCHAR(50) = 'A001' -- 門市Id

BEGIN
	SET NOCOUNT ON;

	DECLARE @cardTypeCode varchar(50);
	set @cardTypeCode = (select top 1 CardTypeCode from VIP_CardInfo where EnterPriseID=@enterpriseId and MemberNO=@memberNo)

	-- 修正有效期間計算邏輯
	SELECT
		vtt.TicketTypeCode AS CouponId
	   ,vtt.PicUrl AS imageUrl
	   ,vtt.TicketTypeName AS couponName
	   ,CASE 
			-- 根據券型的ValidType決定顯示方式
			WHEN vtt.ValidType = 1 THEN CAST(GETDATE() AS DATE) -- 天數制：從今天開始
			WHEN vtt.ValidType = 2 AND vtt.ExpiredDate IS NOT NULL THEN vtr.BeginDate -- 固定日期制：使用規則開始日期
			ELSE vtr.BeginDate -- 預設使用規則開始日期
		END AS startDate
	   ,CASE 
			-- 根據券型的ValidType和ValidDays計算結束日期
			WHEN vtt.ValidType = 1 AND vtt.ValidDays > 0 THEN 
				CAST(DATEADD(day, vtt.ValidDays, GETDATE()) AS DATE) -- 天數制：今天+有效天數
			WHEN vtt.ValidType = 2 AND vtt.ExpiredDate IS NOT NULL THEN 
				vtt.ExpiredDate -- 固定日期制：使用券型的過期日期
			ELSE vtr.EndDate -- 預設使用規則結束日期
		END AS stopDate
	   ,vtrptt.Points AS pointsRequired
	   ,vtrptt.PresentTicketTimes AS remainingCount
	   ,vtrptt.TradeRuleCode
	   ,vtrs.ShopID
	FROM VIP_TradeRules_PointToTicket vtrptt
	JOIN VIP_TradeRules vtr
		ON vtrptt.EnterPriseID = vtr.EnterPriseID
			AND vtrptt.TradeRuleCode = vtr.TradeRuleCode
			AND vtr.CardTypeCode=@cardTypeCode -- 加入卡別條件
	JOIN VIP_TicketType vtt
		ON vtrptt.EnterPriseID = vtt.EnterPriseID
			AND vtrptt.TicketTypeCode = vtt.TicketTypeCode
	LEFT JOIN VIP_TradeRuleShops vtrs
		ON vtr.EnterPriseID=vtrs.EnterPriseID 
			AND vtr.TradeRuleCode = vtrs.TradeRuleCode
	WHERE vtrptt.EnterPriseID = @enterpriseId
	AND vtrptt.PresentTicketTimes > 0
	AND (vtr.EndDate >= convert(varchar,GETDATE(),112) or vtr.EndDate is null) -- 兌換規則仍在有效期內
	AND ((SELECT COUNT(1) FROM VIP_TradeRuleShops WHERE EnterPriseID=vtr.EnterPriseID and TradeRuleCode=vtr.TradeRuleCode)=0 OR vtrs.ShopID=@shopId) -- 點數換券by門店規則
	order BY vtrptt.Points,vtrptt.TicketTypeCode
END
GO
