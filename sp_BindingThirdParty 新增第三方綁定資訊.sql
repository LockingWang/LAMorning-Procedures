SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_BindingThirdParty]   
    @enterpriseId NVARCHAR(50) = NULL,   -- 企業號Id   
    @memberNo NVARCHAR(100) = NULL,      -- 會員帳號   
    @thirdPartyId NVARCHAR(100) = NULL,  -- 第三方登入唯一識別碼
    @isFrom NVARCHAR(50) = NULL,         -- 第三方來源
    @status NVARCHAR(30) OUTPUT          -- 狀態回傳參數（success、no_member、third_data_exist）
AS   
BEGIN   
    SET NOCOUNT ON;   
   
    -- 宣告變數  
    DECLARE @memberGID UNIQUEIDENTIFIER;  
    DECLARE @memberEmail NVARCHAR(200);  
    DECLARE @memberName NVARCHAR(50);  
   
    -- 先透過 enterpriseId、memberNo 到 O_Members 表中查找會員資訊  
    SELECT   
        @memberGID = GID,  
        @memberEmail = Email,  
        @memberName = Name
    FROM O_Members   
    WHERE EnterpriseID = @enterpriseId   
        AND Account = @memberNo;  
   
    -- 如果查不到資料，回傳 no_member  
    IF @memberGID IS NULL  
    BEGIN  
        SET @status = N'no_member';  
        RETURN;  
    END  
   
    -- 檢查 O_MembersThird 是否已存在該 MT_ID  
    IF EXISTS (  
        SELECT 1 FROM O_MembersThird WHERE MT_ID = @thirdPartyId AND EnterpriseID = @enterpriseId AND isFrom = @isFrom
    )  
    BEGIN  
        SET @status = N'third_data_exist';  
        RETURN;  
    END  
   
    -- 插入 O_MembersThird  
    INSERT INTO O_MembersThird (  
        GID,  
        EnterpriseID,  
        isFrom,  
        MB_GID,  
        MT_ID,  
        MT_Email,  
        MT_NickName,  
        CreateDate,  
        CreateUser,  
        LastOP  
    )  
    VALUES (  
        NEWID(),  
        @enterpriseId,  
        @isFrom,  
        @memberGID,  
        @thirdPartyId,  
        @memberEmail,  
        @memberName,  
        GETDATE(),  
        @memberNo,  
        @memberNo  
    );  
   
    -- 插入成功，回傳 success  
    SET @status = N'success';  
END 
GO
