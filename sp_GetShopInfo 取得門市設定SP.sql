/*
預存程序名稱：sp_GetShopInfo
功能說明：取得門市相關設定資訊，包含外帶、外送、內用設定、桌位資訊、橫幅圖片等
參數說明：
    @EnterpriseID VARCHAR(20) - 企業ID
    @ShopID VARCHAR(10) - 門市ID
*/
CREATE OR ALTER PROCEDURE [dbo].[sp_GetShopInfo]
    @EnterpriseID VARCHAR(20),
    @ShopID VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- 取得各種模式的設定值（外帶、外送、內用）
    ;WITH SettingsData AS (
        SELECT 
            CASE ASM.ModeID
                WHEN 'takeout' THEN 'takeoutSettings'
                WHEN 'delivery' THEN 'deliverySettings'
                WHEN 'scaneDesk' THEN 'dineInSettings'' THEN 'appSttings
            END AS SettingType,
            ASD.Name AS Name,
            CASE 
                WHEN ASS.Value IS NOT NULL THEN ASS.Value 
                ELSE ASD.DefaultValue 
            END AS Value
        FROM S_AppSetting_D ASD 
        JOIN S_AppSetting_M ASM ON ASM.GID = ASD.AppSetting_M_GID 
            AND ASM.ModeID IN ('takeout', 'delivery', 'scaneDesk') 
        LEFT JOIN S_AppSetting_Shop ASS ON ASS.AppSetting_D_GID = ASD.GID 
            AND ASS.EnterpriseID = @EnterpriseID 
            AND ASS.ShopID = @ShopID
    ),
    -- 取得企業橫幅圖片路徑
    BannerData AS (
        SELECT TOP 1 Dir AS bannerImagePath
        FROM S_UploadFile 
        WHERE enterpriseid = @EnterpriseID 
        AND vType = 'E_Banner'
    ),
    -- 取得門市桌位資訊
    DeskData AS (
        SELECT 
            GID AS id,
            Name AS name,
            SeatNum AS seatNum
        FROM T_DESK
        WHERE EnterpriseID = @EnterpriseID
        AND ShopID = @ShopID
    ),
    -- 取得門市基本資訊
    ShopData AS (
        SELECT 
            OrgName AS shopName,
            OrgCode AS shopID,
            Addr AS shopAddress
        FROM S_Organ
        WHERE EnterpriseID = @EnterpriseID
        AND OrgCode = @ShopID
    )
    -- 組合所有資訊並以 JSON 格式回傳
    SELECT 
        (
            SELECT 
                -- 外帶設定
                (
                    SELECT 
                        Name AS [key],
                        Value AS value
                    FROM SettingsData
                    WHERE SettingType = 'takeoutSettings'
                    FOR JSON PATH
                ) AS takeoutSettings,
                -- 內用設定
                (
                    SELECT
                        Name AS [key],
                        Value AS value
                    FROM SettingsData
                    WHERE SettingType = 'dineInSettings'
                    FOR JSON PATH
                ) AS dineInSettings,
                -- 外送設定
                (
                    SELECT
                        Name AS [key],
                        Value AS value
                    FROM SettingsData
                    WHERE SettingType = 'deliverySettings'
                    FOR JSON PATH
                ) AS deliverySettings,
                -- 桌位資訊
                (
                    SELECT *
                    FROM DeskData
                    FOR JSON PATH
                ) AS dineInTables,
                -- 橫幅圖片路徑
                (SELECT bannerImagePath FROM BannerData) AS bannerImagePath,
                -- 門市基本資訊
                JSON_QUERY((
                    SELECT 
                        ShopName,
                        ShopID,
                        ShopAddress
                    FROM ShopData
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                )) AS shopInfo,
                -- 發票設定
                JSON_QUERY('{ 
                  "IsEnabled": true, 
                  "InvoiceTypes": { 
                      "PERSONAL": "個人發票", 
                      "COMPANY": "公司發票", 
                      "DONATION": "捐贈發票" 
                  } 
                }') AS InvoiceSettings
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS Result
END


