CREATE or ALTER PROCEDURE [dbo].[sp_RegVIP] 
    @enterpriseId NVARCHAR(50),         -- 企業號 ID 
    @lineUId NVARCHAR(100),             -- LINE ID 
    @email NVARCHAR(50),                -- 信箱 
    @phone NVARCHAR(50),                -- 電話 
    @name NVARCHAR(100),                -- 姓名 
    @sex INT,                          -- 性別 1男 0女 
    @MT_NickName NVARCHAR(100),        -- LINE暱稱 
    @password NVARCHAR(20) OUTPUT,      -- 隨機密碼 OUTPUT 回傳 
    @isFrom NVARCHAR(20) = 'LINElogin', -- 來源，預設 LINElogin 
    @MemberType NVARCHAR(10) = 'K'      -- 會員類型，預設 'K' 
AS 
BEGIN 
    SET NOCOUNT ON; 
 
    -- 產生六位數隨機密碼（英數混合） 
    SET @password = ( 
        SELECT TOP 1 SUBSTRING(REPLACE(CONVERT(varchar(40), NEWID()), '-', ''), 1, 6) 
    ); 
 
    -- 預先產生 GUID 
    DECLARE @vipCardInfoGID UNIQUEIDENTIFIER = NEWID(); 
    DECLARE @vipInfoGID UNIQUEIDENTIFIER = NEWID(); 
    DECLARE @memberGID UNIQUEIDENTIFIER = NEWID(); 
    DECLARE @thirdGID UNIQUEIDENTIFIER = NEWID(); 
 
    -- 新增 VIP_CardInfo 資料 
    INSERT INTO VIP_CardInfo ( 
        GID, 
        CardNO, 
        CardID, 
        MemberNO, 
        LastOP, 
        WeChatOpenID, 
        CardTypeCode, 
        EnterPriseID, 
        PassWord 
    ) 
    VALUES ( 
        @vipCardInfoGID, 
        @phone, @phone, @phone, @phone, @phone, 
        @MemberType,      -- 使用 MemberType 作為 CardTypeCode 
        @enterpriseId, 
        @password 
    ); 
 
    -- 新增 VIP_Info 資料 
    INSERT INTO VIP_Info ( 
        GID, 
        LastOP, 
        EnterPriseID, 
        MemberNO, 
        CardNO, 
        CardID, 
        Mobile, 
        Email, 
        MemberType 
    ) 
    VALUES ( 
        @vipInfoGID, 
        @phone, 
        @enterpriseId, 
        @phone, 
        @phone, 
        @phone, 
        @phone, 
        @email, 
        @MemberType 
    ); 
 
    -- 新增 O_Members 資料 
    INSERT INTO O_Members ( 
        GID, 
        EnterpriseID, 
        Account, 
        Password, 
        Email, 
        Phone, 
        CreateUser, 
        UpdateUser, 
        LastOP, 
        isFrom, 
        Name, 
        Sex, 
        Type 
    ) 
    VALUES ( 
        @memberGID, 
        @enterpriseId, 
        @phone, 
        @password, 
        @email, 
        @phone, 
        @phone, 
        @phone, 
        @phone, 
        @isFrom, 
        @name, 
        @sex, 
        1   -- Type 預設1 
    ); 
 
    -- 新增 O_MembersThird 資料 
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
        @thirdGID, 
        @enterpriseId, 
        @isFrom, 
        @memberGID, 
        @lineUId, 
        @email, 
        @MT_NickName, 
        GETDATE(), 
        @phone, 
        @phone 
    ); 

    -- 新增 LA_App_MemberDevice 資料 
    INSERT INTO LA_App_MemberDevice ( 
        GID,
        MemberID,
        DeviceType,
        DeviceID,
        IsReceive,
        CreateTime,
        UpdateTime
    ) 
    VALUES ( 
        NEWID(),
        @memberGID,
        @isFrom,
        @lineUId,
        1,
        GETDATE(),
        GETDATE()
    ); 
END; 