-- ========================================
-- 1. 處理 S_Parameter_Enterprise 三個參數
-- ========================================

-- APPSMSDayTimes
MERGE INTO S_Parameter_Enterprise AS target
USING (
    SELECT s.GID AS ParameterGID, s.ParameterValue AS DefaultValue
    FROM S_Parameter_System s
    WHERE s.ParameterName = 'APPSMSDayTimes'
) AS src
ON target.EnterPriseID = :EnterpriseID
   AND target.ParameterGID = src.ParameterGID
WHEN MATCHED THEN
    UPDATE SET target.ParameterValue = ISNULL(':APPSMSDayTimesValue', src.DefaultValue),
               target.LastModify = GETDATE(),
               target.LastOP = ':LastOP'
WHEN NOT MATCHED THEN
    INSERT (GID, EnterPriseID, ParameterGID, ParameterValue, LastModify, LastOP)
    VALUES (NEWID(), :EnterpriseID, src.ParameterGID, ISNULL(':APPSMSDayTimesValue', src.DefaultValue), GETDATE(), ':LastOP');

-- AppSMSIntervalMin
MERGE INTO S_Parameter_Enterprise AS target
USING (
    SELECT s.GID AS ParameterGID, s.ParameterValue AS DefaultValue
    FROM S_Parameter_System s
    WHERE s.ParameterName = 'AppSMSIntervalMin'
) AS src
ON target.EnterPriseID = :EnterpriseID
   AND target.ParameterGID = src.ParameterGID
WHEN MATCHED THEN
    UPDATE SET target.ParameterValue = ISNULL(':AppSMSIntervalMinValue', src.DefaultValue),
               target.LastModify = GETDATE(),
               target.LastOP = ':LastOP'
WHEN NOT MATCHED THEN
    INSERT (GID, EnterPriseID, ParameterGID, ParameterValue, LastModify, LastOP)
    VALUES (NEWID(), :EnterpriseID, src.ParameterGID, ISNULL(':AppSMSIntervalMinValue', src.DefaultValue), GETDATE(), ':LastOP');

-- AppSMSRegCode
MERGE INTO S_Parameter_Enterprise AS target
USING (
    SELECT s.GID AS ParameterGID, s.ParameterValue AS DefaultValue
    FROM S_Parameter_System s
    WHERE s.ParameterName = 'AppSMSRegCode'
) AS src
ON target.EnterPriseID = :EnterpriseID
   AND target.ParameterGID = src.ParameterGID
WHEN MATCHED THEN
    UPDATE SET target.ParameterValue = ISNULL(':AppSMSRegCodeValue', src.DefaultValue),
               target.LastModify = GETDATE(),
               target.LastOP = ':LastOP'
WHEN NOT MATCHED THEN
    INSERT (GID, EnterPriseID, ParameterGID, ParameterValue, LastModify, LastOP)
    VALUES (NEWID(), :EnterpriseID, src.ParameterGID, ISNULL(':AppSMSRegCodeValue', src.DefaultValue), GETDATE(), ':LastOP');

-- ========================================
-- 2. 處理 O_AppSMSUrlApi 帳號密碼（含 LastOP / CreateOP）
-- ========================================
MERGE INTO O_AppSMSUrlApi AS target
USING (SELECT :EnterpriseID AS EnterpriseID) AS src
ON target.EnterPriseID = src.EnterpriseID
WHEN MATCHED THEN
    UPDATE SET target.AppSMSuser = ':AppSMSUser',
               target.AppSMSpassword = ':AppSMSpassword',
               target.LastModify = GETDATE(),
               target.LastOP = ':LastOP'
WHEN NOT MATCHED THEN
    INSERT (GID, EnterPriseID, CountryCode, AppSMSuser, AppSMSpassword, AppSMSOffer, LastModify, CreateDate, LastOP, CreateOP, AppSMSaeskey, AppSMSSubAccount)
    VALUES (NEWID(), :EnterpriseID, '886',':AppSMSUser', ':AppSMSpassword', 'EVERY8D', GETDATE(), GETDATE(), ':LastOP', ':CreateOP', '', '');