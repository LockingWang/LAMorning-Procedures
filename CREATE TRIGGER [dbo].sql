CREATE TRIGGER [dbo].[tr_AutoCreateQRCode_XF42792721] ON [dbo].[O_Members] 
AFTER INSERT 
AS 
BEGIN     
    SET NOCOUNT ON;          
    
    -- 為新加入的XF42792721企業會員自動創建QR Code     
    INSERT INTO O_QrCodeData (         
        GID,         
        EnterpriseID,         
        Account,         
        QrCodeType,         
        QrCodeMd5sp,         
        QrCodeMd5,         
        QrCodeBackData,         
        QrCodeBackUrl,         
        CreateDate,         
        ExpiredDate,         
        ExpiredType,         
        UseCount,         
        UseDate,         
        UseType,         
        UseTradeType     
    )     
    SELECT          
        NEWID(),         
        'xurf',         
        '',         
        'member',         
        'mbr' + i.Phone + 'auto',         
        'mbr' + i.Phone + 'auto',         
        '{' +
            '"nonce":"AUTO' + RIGHT('000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000 AS VARCHAR), 6) + '",' +
            '"EnterpriseID":"XF42792721",' +
            '"path":"member",' +
            '"appQrcode":"' + RIGHT(i.Phone, 6) + '",' +
            '"linePara":"' + LOWER(LEFT(CONVERT(VARCHAR(16), HASHBYTES('SHA1', i.Phone + i.Name + 'jinher-*&sdF11d'), 2), 16)) + '",' +
            '"generatedDate":"' + CONVERT(VARCHAR, GETDATE(), 127) + '",' +
            '"repairSource":"AUTO_TRIGGER_XF42792721",' +
            '"memberInfo":{' +
                '"account":"' + i.Account + '",' +
                '"name":"' + REPLACE(i.Name, '"', '\"') + '",' +
                '"enterpriseID":"XF42792721",' +
                '"phone":"' + i.Phone + '"' +
            '}' +
        '}',         
        'https://web.cloudxurf.com.tw/xurfmember/index.html?linePara=' + LOWER(LEFT(CONVERT(VARCHAR(16), HASHBYTES('SHA1', i.Phone + i.Name + 'jinher-*&sdF11d'), 2), 16)),         
        GETDATE(),         
        DATEADD(YEAR, 1, GETDATE()),         
        'date',         
        0,         
        NULL,         
        NULL,         
        NULL     
    FROM inserted i     
    WHERE i.EnterPriseID = 'XF42792721' 
        AND 1=2 --測試新增，先拿掉       
        AND NOT EXISTS (           
            SELECT 1 
            FROM O_QrCodeData qr            
            WHERE qr.Account = i.Phone       
        ); 
END;