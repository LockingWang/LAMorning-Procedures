SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_UpdateVIPInfo] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @memberNo NVARCHAR(50), -- 會員No 
    @MemberName NVARCHAR(50), -- 會員名稱 
    @Gender NVARCHAR(2), -- 性別 
    @Birthday NVARCHAR(10) = NULL, -- 出生年月日 
    @Phone NVARCHAR(20), -- 手機號碼 
    @Email NVARCHAR(100), -- 電子信箱 
	@CarrierId NVARCHAR(100) = NULL, -- 載具號碼
    @Address NVARCHAR(200), -- 地址 
    @DefaultShopId NVARCHAR(50) -- 預設門市 
AS 
BEGIN 
    SET NOCOUNT ON; 
     
	UPDATE VIP_Info
	SET CnName = @MemberName, Sex = @Gender, BirthDay = CASE
		WHEN @Birthday = '' OR @Birthday IS NULL THEN NULL
		ELSE CAST(@Birthday AS DATE) 
	END, Mobile = @Phone, Email = @Email, Addr = @Address, CarrierId = @CarrierId, LastModify = GETDATE(), LastOP = @MemberNO
	WHERE MemberNO = @MemberNO
	AND EnterPriseID = @enterpriseId;

	 
	UPDATE O_Members 
	SET  
	    Account = @MemberNO,  
	    Birthday = CASE 
	        WHEN @Birthday = '' OR @Birthday IS NULL THEN NULL 
	        ELSE CAST(@Birthday AS DATE) 
	    END,  
	    Sex = CASE  
	            WHEN @Gender = '男' THEN 1 
	            WHEN @Gender = '女' THEN 0 
	            ELSE NULL  
	          END,  
	    Name = @MemberName,  
	    Email = @Email,  
	    Address = @Address,  
	    favEnterprise = @DefaultShopId,  
	    LastModify = GETDATE(),  
	    LastOP = @MemberNO 
	WHERE Account = @MemberNO 
	AND EnterpriseID = @enterpriseId;
	 
	UPDATE VIP_CardInfo 
	SET CardNO = @MemberNO, MemberNO = @MemberNO, WeChatOpenID = @Phone, CardID = @Phone, LastModify = GETDATE(), LastOP = @MemberNO 
	WHERE MemberNO = @MemberNO
	AND EnterPriseID = @enterpriseId
	 
END
GO
