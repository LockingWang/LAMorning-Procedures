CREATE OR ALTER PROCEDURE [dbo].[sp_BindingLine]  
    @enterpriseId NVARCHAR(50),   -- 企業號Id  
    @memberNo NVARCHAR(100),      -- 會員帳號  
    @lineUId NVARCHAR(100),       -- Line UID  
    @status NVARCHAR(30) OUTPUT   -- 狀態回傳參數（success、no_member、third_data_exist） 
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    -- 宣告變數 
    DECLARE @memberGID UNIQUEIDENTIFIER; 
    DECLARE @memberEmail NVARCHAR(50); 
    DECLARE @memberName NVARCHAR(100); 
  
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
        SELECT 1 FROM O_MembersThird WHERE MT_ID = @lineUId AND EnterpriseID = @enterpriseId
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
        'LINElogin', 
        @memberGID, 
        @lineUId, 
        @memberEmail, 
        @memberName, 
        GETDATE(), 
        @enterpriseId, 
        @enterpriseId 
    ); 
  
    -- 插入成功，回傳 success 
    SET @status = N'success'; 
END 