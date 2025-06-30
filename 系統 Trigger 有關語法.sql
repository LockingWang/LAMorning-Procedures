SELECT * FROM sys.triggers 
WHERE parent_id = '610869293'


-- 查詢特定資料表的 object_id
SELECT 
    name AS TableName,
    object_id,
    schema_id,
    type_desc
FROM sys.objects 
WHERE type = 'U'  -- U 表示 User Table
    AND name IN ('VIP_CardInfo', 'VIP_Info', 'O_Members', 'O_MembersThird', 'VIP_Trade', 'VIP_TicketInfo', 'O_QrCodeData');


-- SELECT OBJECT_DEFINITION(OBJECT_ID('tr_AutoCreateQRCode_XF42792721')) AS TriggerDefinition;

-- SELECT OBJECT_DEFINITION(OBJECT_ID('trg_O_QrCodeData_PreventNull')) AS TriggerDefinition;


-- -- 1. 先查看觸發器狀態
-- SELECT 
--     name AS TriggerName,
--     OBJECT_NAME(parent_id) AS TableName,
--     is_disabled
-- FROM sys.triggers 
-- WHERE name = 'tr_AutoCreateQRCode_XF42792721';

-- -- 2. 停用觸發器
-- DISABLE TRIGGER tr_AutoCreateQRCode_XF42792721 ON [O_Members];

-- -- 3. 確認觸發器已停用
-- SELECT 
--     name AS TriggerName,
--     OBJECT_NAME(parent_id) AS TableName,
--     is_disabled
-- FROM sys.triggers 
-- WHERE name = 'tr_AutoCreateQRCode_XF42792721';