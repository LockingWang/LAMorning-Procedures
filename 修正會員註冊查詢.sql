-- 修正版本的會員註冊查詢語句
-- 原始問題分析：
-- 1. 如果 VIP_CardType 查詢沒有結果，@validDays 會是 NULL
-- 2. 如果 VIP_TradeRules 查詢沒有結果，@tradeRuleCode 會是 NULL
-- 3. 使用 NULL 的 @validDays 計算日期可能會有問題

DECLARE @enterpriseId NVARCHAR(50) = '90367984'
DECLARE @MemberType NVARCHAR(10) = 'K'

-- 修正版本 1: 使用 ISNULL 提供預設值
DECLARE @memberLevel NVARCHAR(50)
DECLARE @validDays INT
DECLARE @createDate DATETIME = (SELECT CAST(GETDATE() AS DATE))
DECLARE @expiredDate DATETIME
DECLARE @tradeRuleCode VARCHAR(50)

-- 查詢 VIP_CardType 並提供預設值
SELECT @memberLevel = ISNULL(vct.CardTypeName, '一般會員'),
       @validDays = ISNULL(vct.ValidDays, 365)  -- 預設一年
FROM VIP_CardType vct    
WHERE vct.EnterPriseID = @enterpriseId AND vct.CardTypeCode = @MemberType

-- 如果沒有找到資料，設定預設值
IF @memberLevel IS NULL
BEGIN
    SET @memberLevel = '一般會員'
    SET @validDays = 365
END

-- 計算過期日期
SET @expiredDate = DATEADD(DAY, @validDays, @createDate)

-- 查詢 VIP_TradeRules 並提供預設值
SELECT @tradeRuleCode = ISNULL(TradeRuleCode, 'DEFAULT_RULE')
FROM VIP_TradeRules vtr 
WHERE vtr.EnterPriseID = @enterpriseId AND vtr.TradeTypeCode = 1

-- 如果沒有找到資料，設定預設值
IF @tradeRuleCode IS NULL
BEGIN
    SET @tradeRuleCode = 'DEFAULT_RULE'
END

-- 顯示結果
PRINT '=== 修正後的查詢結果 ==='
PRINT 'memberLevel = ' + @memberLevel
PRINT 'validDays = ' + CAST(@validDays AS VARCHAR)
PRINT 'createDate = ' + CONVERT(VARCHAR, @createDate, 120)
PRINT 'expiredDate = ' + CONVERT(VARCHAR, @expiredDate, 120)
PRINT 'tradeRuleCode = ' + @tradeRuleCode

-- 修正版本 2: 使用 CASE WHEN 處理查詢結果
PRINT ''
PRINT '=== 使用 CASE WHEN 的版本 ==='

DECLARE @memberLevel2 NVARCHAR(50)
DECLARE @validDays2 INT
DECLARE @expiredDate2 DATETIME
DECLARE @tradeRuleCode2 VARCHAR(50)

-- 使用 CASE WHEN 處理查詢結果
SELECT @memberLevel2 = CASE 
    WHEN vct.CardTypeName IS NOT NULL THEN vct.CardTypeName 
    ELSE '一般會員' 
END,
@validDays2 = CASE 
    WHEN vct.ValidDays IS NOT NULL THEN vct.ValidDays 
    ELSE 365 
END
FROM VIP_CardType vct    
WHERE vct.EnterPriseID = @enterpriseId AND vct.CardTypeCode = @MemberType

-- 如果查詢沒有結果，設定預設值
IF @memberLevel2 IS NULL
BEGIN
    SET @memberLevel2 = '一般會員'
    SET @validDays2 = 365
END

SET @expiredDate2 = DATEADD(DAY, @validDays2, @createDate)

-- 使用 CASE WHEN 處理 TradeRules 查詢
SELECT @tradeRuleCode2 = CASE 
    WHEN TradeRuleCode IS NOT NULL THEN TradeRuleCode 
    ELSE 'DEFAULT_RULE' 
END
FROM VIP_TradeRules vtr 
WHERE vtr.EnterPriseID = @enterpriseId AND vtr.TradeTypeCode = 1

IF @tradeRuleCode2 IS NULL
BEGIN
    SET @tradeRuleCode2 = 'DEFAULT_RULE'
END

PRINT 'memberLevel2 = ' + @memberLevel2
PRINT 'validDays2 = ' + CAST(@validDays2 AS VARCHAR)
PRINT 'expiredDate2 = ' + CONVERT(VARCHAR, @expiredDate2, 120)
PRINT 'tradeRuleCode2 = ' + @tradeRuleCode2 