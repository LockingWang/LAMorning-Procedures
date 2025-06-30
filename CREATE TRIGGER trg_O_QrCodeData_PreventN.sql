CREATE TRIGGER trg_O_QrCodeData_PreventNull 
ON O_QrCodeData 
AFTER INSERT, UPDATE 
AS 
BEGIN     
    SET NOCOUNT ON;          
    
    -- 自動修復插入或更新時的空值     
    UPDATE O_QrCodeData      
    SET QrCodeBackData = CASE          
        WHEN i.QrCodeBackUrl LIKE '%AppSMSsendOneEntry%' THEN              
            '{
                "type": "SMS_VERIFICATION",
                "nonce": "' + SUBSTRING(CAST(NEWID() AS VARCHAR(50)), 1, 6) + '",
                "EnterpriseID": "SMS_SYSTEM",
                "path": "sms",
                "appQrcode": "SMS",
                "generatedDate": "' + CONVERT(VARCHAR, GETDATE(), 126) + '",
                "repairSource": "TRIGGER_AUTO_REPAIR"
            }'
        WHEN i.QrCodeBackUrl LIKE '%xurfmember%' THEN              
            '{
                "nonce": "' + SUBSTRING(CAST(NEWID() AS VARCHAR(50)), 1, 6) + '",
                "EnterpriseID": "' + CASE                  
                    WHEN i.EnterpriseID = 'jinher' THEN 'XF93304154'                 
                    WHEN i.EnterpriseID = 'xurf' THEN 'XF42792721'                 
                    ELSE 'XF' + CAST(ABS(CHECKSUM(i.EnterpriseID)) % 100000000 AS VARCHAR(8))             
                END + '",
                "path": "member",
                "appQrcode": "' + CAST(ABS(CHECKSUM(i.QrCodeMd5sp)) % 1000000 AS VARCHAR(6)) + '",
                "generatedDate": "' + CONVERT(VARCHAR, GETDATE(), 126) + '",
                "repairSource": "TRIGGER_AUTO_REPAIR"
            }'
        ELSE              
            '{
                "type": "AUTO_GENERATED",
                "nonce": "' + SUBSTRING(CAST(NEWID() AS VARCHAR(50)), 1, 6) + '",
                "EnterpriseID": "AUTO",
                "path": "auto", 
                "appQrcode": "AUTO",
                "generatedDate": "' + CONVERT(VARCHAR, GETDATE(), 126) + '",
                "repairSource": "TRIGGER_FALLBACK"
            }'
    END     
    FROM O_QrCodeData qr     
    INNER JOIN inserted i ON qr.GID = i.GID     
    WHERE (qr.QrCodeBackData IS NULL OR qr.QrCodeBackData = '');
END;