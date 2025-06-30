-- 測試會員註冊中的查詢語句
-- 設定測試參數
DECLARE @enterpriseId NVARCHAR(50) = '90367984'
DECLARE @MemberType NVARCHAR(10) = 'K'

-- 測試 1: 檢查 VIP_CardType 表查詢
PRINT '=== 測試 VIP_CardType 查詢 ==='
DECLARE @memberLevel NVARCHAR(50)
DECLARE @validDays INT

-- 先檢查表是否存在資料
SELECT 'VIP_CardType 表資料' as 測試項目, COUNT(*) as 資料筆數 
FROM VIP_CardType 
WHERE EnterPriseID = @enterpriseId

-- 檢查特定條件的資料
SELECT 'VIP_CardType 符合條件的資料' as 測試項目, 
       CardTypeCode, CardTypeName, ValidDays
FROM VIP_CardType 
WHERE EnterPriseID = @enterpriseId AND CardTypeCode = @MemberType

-- 執行實際的查詢並顯示結果
SELECT @memberLevel = vct.CardTypeName, @validDays = vct.ValidDays 
FROM VIP_CardType vct    
WHERE vct.EnterPriseID = @enterpriseId AND vct.CardTypeCode = @MemberType

PRINT '查詢結果:'
PRINT 'memberLevel = ' + ISNULL(@memberLevel, 'NULL')
PRINT 'validDays = ' + ISNULL(CAST(@validDays AS VARCHAR), 'NULL')

-- 測試 2: 檢查 VIP_TradeRules 表查詢
PRINT ''
PRINT '=== 測試 VIP_TradeRules 查詢 ==='
DECLARE @tradeRuleCode VARCHAR(50)

-- 先檢查表是否存在資料
SELECT 'VIP_TradeRules 表資料' as 測試項目, COUNT(*) as 資料筆數 
FROM VIP_TradeRules 
WHERE EnterPriseID = @enterpriseId

-- 檢查特定條件的資料
SELECT 'VIP_TradeRules 符合條件的資料' as 測試項目, 
       TradeTypeCode, TradeRuleCode
FROM VIP_TradeRules 
WHERE EnterPriseID = @enterpriseId AND TradeTypeCode = 1

-- 執行實際的查詢並顯示結果
SELECT @tradeRuleCode = TradeRuleCode 
FROM VIP_TradeRules vtr 
WHERE vtr.EnterPriseID = @enterpriseId AND vtr.TradeTypeCode = 1

PRINT '查詢結果:'
PRINT 'tradeRuleCode = ' + ISNULL(@tradeRuleCode, 'NULL')

-- 測試 3: 檢查日期計算
PRINT ''
PRINT '=== 測試日期計算 ==='
DECLARE @createDate DATETIME = (SELECT CAST(GETDATE() AS DATE))
DECLARE @expiredDate DATETIME

IF @validDays IS NOT NULL
BEGIN
    SET @expiredDate = DATEADD(DAY, @validDays, @createDate)
    PRINT 'createDate = ' + CONVERT(VARCHAR, @createDate, 120)
    PRINT 'validDays = ' + CAST(@validDays AS VARCHAR)
    PRINT 'expiredDate = ' + CONVERT(VARCHAR, @expiredDate, 120)
END
ELSE
BEGIN
    PRINT '警告: validDays 為 NULL，無法計算過期日期'
END

-- 測試 4: 檢查所有相關表的資料
PRINT ''
PRINT '=== 檢查相關表資料 ==='
SELECT 'VIP_CardType' as 表名, COUNT(*) as 資料筆數 FROM VIP_CardType WHERE EnterPriseID = @enterpriseId
UNION ALL
SELECT 'VIP_TradeRules' as 表名, COUNT(*) as 資料筆數 FROM VIP_TradeRules WHERE EnterPriseID = @enterpriseId
UNION ALL
SELECT 'VIP_CardInfo' as 表名, COUNT(*) as 資料筆數 FROM VIP_CardInfo WHERE EnterPriseID = @enterpriseId
UNION ALL
SELECT 'VIP_Info' as 表名, COUNT(*) as 資料筆數 FROM VIP_Info WHERE EnterPriseID = @enterpriseId
UNION ALL
SELECT 'O_Members' as 表名, COUNT(*) as 資料筆數 FROM O_Members WHERE EnterpriseID = @enterpriseId 