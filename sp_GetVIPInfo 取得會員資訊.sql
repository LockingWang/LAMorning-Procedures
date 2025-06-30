CREATE OR ALTER PROCEDURE [dbo].[sp_GetVIPInfo] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @memberNo NVARCHAR(50) -- 會員No 
AS 

-- DECLARE @enterpriseId NVARCHAR(50) = '企業號' -- 企業號Id 
-- DECLARE @memberNo NVARCHAR(50) = '手機號碼' -- 會員No 

BEGIN 
    SET NOCOUNT ON; 
         
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
	    O_Members.favEnterprise AS defaultShopId,
        (SELECT OrgName FROM S_Organ WHERE S_Organ.enterpriseId = @enterpriseId AND S_Organ.OrgCode = O_Members.favEnterprise) AS DefaultShop,
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
        AND O_Members.EnterPriseID = @enterpriseId
	WHERE  
	    VIP_Info.MemberNO = @MemberNO  
	    AND VIP_Info.EnterPriseID = @EnterpriseID   
END