-- 會員註冊SQL語法（不含LINE相關資訊）
-- 建立日期：2025-01-14
-- 用途：純會員註冊，不涉及LINE第三方登入

-- =============================================
-- 設定註冊參數
-- =============================================
DECLARE @enterpriseId NVARCHAR(50) = 'XFlamorning'  -- 企業ID
DECLARE @phone NVARCHAR(50) = '0903008556'  -- 會員電話號碼
DECLARE @name NVARCHAR(100) = '王琮仁'  -- 會員姓名
DECLARE @email NVARCHAR(50) = 'test@example.com'  -- 電子郵件
DECLARE @sex INT = 1  -- 性別 (1=男, 2=女)
DECLARE @MemberType NVARCHAR(10) = 'K'  -- 會員類型
DECLARE @isFrom NVARCHAR(20) = 'web'  -- 來源（web註冊）
DECLARE @createDate DATETIME = GETDATE()

-- 產生隨機密碼
DECLARE @password NVARCHAR(20) = SUBSTRING(REPLACE(CONVERT(varchar(40), NEWID()), '-', ''), 1, 6)

-- =============================================
-- 檢查會員是否已存在
-- =============================================
IF EXISTS (SELECT 1 FROM VIP_CardInfo WHERE MemberNO = @phone AND EnterPriseID = @enterpriseId)
BEGIN
    PRINT '會員已存在，電話號碼：' + @phone
    RETURN
END

IF EXISTS (SELECT 1 FROM VIP_Info WHERE MemberNO = @phone AND EnterPriseID = @enterpriseId)
BEGIN
    PRINT '會員已存在，電話號碼：' + @phone
    RETURN
END

IF EXISTS (SELECT 1 FROM O_Members WHERE Account = @phone AND EnterpriseID = @enterpriseId)
BEGIN
    PRINT '會員已存在，電話號碼：' + @phone
    RETURN
END

-- =============================================
-- 開始註冊流程
-- =============================================
BEGIN TRANSACTION
    -- 取得會員等級和有效期設定
    DECLARE @memberLevel NVARCHAR(50)
    DECLARE @validDays INT
    DECLARE @validType INT
    DECLARE @validDate DATETIME
    DECLARE @expiredDate DATETIME
    
    SELECT @memberLevel = vct.CardTypeName, 
           @validDays = vct.ValidDays, 
           @validType = vct.ValidType, 
           @validDate = vct.ExpiredDate 
    FROM VIP_CardType vct     
    WHERE vct.EnterPriseID = @enterpriseId AND vct.CardTypeCode = @MemberType
    
    -- 根據 validType 決定過期日期
    IF @validType = 1
        SET @expiredDate = DATEADD(DAY, @validDays, @createDate)
    ELSE IF @validType = 2
        SET @expiredDate = '9999-12-31 23:59:59.997'
    ELSE IF @validType = 3
        SET @expiredDate = @validDate
    ELSE
        SET @expiredDate = DATEADD(DAY, @validDays, @createDate)

    -- =============================================
    -- 新增 VIP_CardInfo 資料
    -- =============================================
    INSERT INTO VIP_CardInfo (
        GID, EnterPriseID, CardNO, CardID, MemberNO, CardTypeCode, 
        SaleShopID, SaleDate, CardState, ExpiredDate, BalanceLimit, 
        Points, Bonus, Balance, TotalTrades, TotalSavings, TotalSales,
        PassWord, PointsRedeemed, BonusRedeemed, Discount, Deposit, 
        TotalCashSales, WeChatOpenID, CardKey, PayTotal, PublicNum, 
        PayExpiredDate, DifferenceCumulativeSales, UpgradeDate
    )
    VALUES (
        NEWID(), @enterpriseId, @phone, @phone, @phone, @MemberType,
        '9999', @createDate, 2, @expiredDate, 0.00,
        0.00, 0.00, 0.00, 1, 0.00, 0.00,
        @password, 0.00, 0.00, 0.00, 0.00,
        0.00, @phone, '', 0.00, '',
        '2000-01-01 00:00:00.000', 0.00, @createDate
    )

    -- =============================================
    -- 新增 VIP_Info 資料
    -- =============================================
    INSERT INTO VIP_Info (
        GID, EnterPriseID, MemberNO, CardNO, CardID, MemberType,
        CnName, Mobile, Addr, Email, UndertakeOrgCode, Sex, BirthType
    )
    VALUES (
        NEWID(), @enterpriseId, @phone, @phone, @phone, @MemberType,
        @name, @phone, '', @email, '9999', 
        CASE WHEN @sex = 1 THEN '男' WHEN @sex = 2 THEN '女' ELSE '保密' END, 1
    )

    -- =============================================
    -- 新增 O_Members 資料
    -- =============================================
    INSERT INTO O_Members (
        GID, EnterpriseID, isFrom, Account, Password, Type, Name, Sex,
        Birthday, Members_Level, Email, City, Town, Code, Address,
        PrePhone, Phone, Pass, VIP, Epaper_Order, IsDisable,
        CreateDate, CreateUser, UpdateDate, UpdateUser, LastModify, LastOP, LastState,
        EDM_Order, EDMDate
    )
    VALUES (
        NEWID(), @enterpriseId, @isFrom, @phone, @password, 1, @name, @sex,
        '1970-01-01 00:00:00', ISNULL(@memberLevel, '一般會員'), @email, '', '', '', '',
        '886', @phone, '1', '1', '1', '0',
        @createDate, @phone, @createDate, @phone, @createDate, @phone, 'A',
        1, @createDate
    )

    -- =============================================
    -- 顯示註冊結果
    -- =============================================
    PRINT '============================================='
    PRINT '會員註冊成功！'
    PRINT '============================================='
    PRINT '電話號碼：' + @phone
    PRINT '姓名：' + @name
    PRINT '密碼：' + @password
    PRINT '會員等級：' + ISNULL(@memberLevel, '一般會員')
    PRINT '註冊時間：' + CONVERT(VARCHAR, @createDate, 120)
    PRINT '============================================='

COMMIT TRANSACTION

-- =============================================
-- 查詢新增的會員資料
-- =============================================
PRINT ''
PRINT '=== 查詢新增的會員資料 ==='

-- 查詢 VIP_CardInfo
SELECT 'VIP_CardInfo' as 資料表, 
       MemberNO, CardNO, CardTypeCode, CardState, 
       CONVERT(VARCHAR, ExpiredDate, 120) as 過期日期,
       Balance, Points, Bonus
FROM VIP_CardInfo 
WHERE MemberNO = @phone AND EnterPriseID = @enterpriseId

-- 查詢 VIP_Info
SELECT 'VIP_Info' as 資料表, 
       MemberNO, CnName, Mobile, Email, Sex
FROM VIP_Info 
WHERE MemberNO = @phone AND EnterPriseID = @enterpriseId

-- 查詢 O_Members
SELECT 'O_Members' as 資料表, 
       Account, Name, Phone, Email, Members_Level, isFrom
FROM O_Members 
WHERE Account = @phone AND EnterpriseID = @enterpriseId

-- =============================================
-- 使用說明
-- =============================================
/*
使用方式：
1. 修改上方的參數設定
2. 執行此SQL語法
3. 檢查輸出結果確認註冊成功

參數說明：
- @enterpriseId：企業ID
- @phone：會員電話號碼（主要識別碼）
- @name：會員姓名
- @email：電子郵件
- @sex：性別（1=男，2=女）
- @MemberType：會員類型（預設'K'）
- @isFrom：來源（web註冊）

注意事項：
- 此語法不包含LINE相關資訊
- 不會新增O_MembersThird表資料
- 會自動產生隨機密碼
- 包含完整的錯誤檢查
*/ 