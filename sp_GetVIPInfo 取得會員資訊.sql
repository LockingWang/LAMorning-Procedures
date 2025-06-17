CREATE PROCEDURE [dbo].[sp_GetVIPInfo] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @memberNo NVARCHAR(50) -- 會員No 
AS 
BEGIN 
    SET NOCOUNT ON; 
     
--    SELECT  
--        'Abby Li' AS MemberName, -- 會員名稱 
--        180 AS TotalPoints, -- 目前積點 
--        8 AS TotalCoupons, -- 目前已有優惠券 
--        '女' AS Gender, -- 性別 
--        '2023-01-06' AS Birthday, -- 出生年月日 
--        '+886 972255956' AS Phone, -- 手機號碼 
--        'cloudxurf@gmail.com' AS Email, -- 電子信箱 
--        '普通卡' AS MemberLevel, -- 會員等級 
--        '2023/11/30' AS ExpiredDate, -- 會員到期日 
--				'114 臺北市, 洲子街69 號' AS Address, -- 地址 
--        '{"Key":"S001","Value":"台北信義店"}' AS DefaultShop, -- 預設門市 
--        'A546742639' AS CardIDQRCode -- 會員QRCode編碼 
         
    SELECT DISTINCT  
	    VIP_Info.CnName AS MemberName, 
	    VIP_CardInfo.ExpiredDate AS ExpiredDate, 
	    VIP_CardInfo.Points AS TotalPoints, 
	    VIP_CardInfo.CardIDQRCode AS CardIDQRCode, 
	    VIP_CardType.CardTypeName AS MemberLevel, 
	    VIP_Info.Sex AS Gender, 
	    VIP_Info.BirthDay AS Birthday, 
	    VIP_Info.Mobile AS Phone, 
	    VIP_Info.Addr AS Address, 
	    VIP_Info.Email AS Email, 
	    O_Members.favEnterprise AS DefaultShop, 
	    (SELECT COUNT(*)  
	     FROM VIP_TicketInfo  
	     WHERE MemberNO = @MemberNO  
	     AND EnterPriseID = @EnterpriseID  
	     AND TicketCount <> 0) AS TotalCoupons 
	FROM  
	    VIP_Info 
	INNER JOIN  
	    VIP_CardInfo  
	    ON VIP_Info.MemberNO = VIP_CardInfo.MemberNO  
	    AND VIP_Info.EnterPriseID = VIP_CardInfo.EnterPriseID 
	INNER JOIN  
	    VIP_CardType  
	    ON VIP_CardInfo.CardTypeCode = VIP_CardType.CardTypeCode  
	    AND VIP_CardInfo.EnterPriseID = VIP_CardType.EnterPriseID 
	LEFT JOIN  
	    O_Members  
	    ON VIP_Info.MemberNO = O_Members.Account 
	WHERE  
	    VIP_Info.MemberNO = @MemberNO  
	    AND VIP_Info.EnterPriseID = @EnterpriseID   
END