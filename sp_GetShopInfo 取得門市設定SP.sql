SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_GetShopInfo]    
    @EnterpriseID VARCHAR(20),    
    @ShopID VARCHAR(10)    
AS   
  
-- DECLARE @EnterpriseID VARCHAR(20) = '90367984',    
-- @ShopID VARCHAR(10) = 'A03'    
  
BEGIN    
    SET NOCOUNT ON;    
    
    ;WITH SettingsData AS (    
        SELECT     
            CASE ASM.ModeID     
                WHEN 'takeout' THEN 'takeoutSettings'    
                WHEN 'delivery' THEN 'deliverySettings'    
                WHEN 'scaneDesk' THEN 'dineInSettings'    
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
    BannerData AS (    
        SELECT TOP 1 Dir AS bannerImagePath    
        FROM S_UploadFile     
        WHERE enterpriseid = @EnterpriseID     
        AND vType = 'E_Banner'    
    ),    
    DeskData AS (    
        SELECT     
            GID AS id,    
            Name AS name,    
            SeatNum AS seatNum    
        FROM T_DESK    
        WHERE EnterpriseID = @EnterpriseID    
        AND ShopID = @ShopID    
    ),    
    ShopData AS (    
        SELECT     
            OrgName AS shopName,    
            OrgCode AS shopID,    
            Addr AS shopAddress,    
			Tel AS shopPhone,
            google_lat AS shopLatitude,
            google_lng AS shopLongitude
        FROM S_Organ    
        WHERE EnterpriseID = @EnterpriseID    
        AND OrgCode = @ShopID    
    ),
    ServiceFeeSetting AS (
        -- 搜尋門市服務費設定
        SELECT FreePercent, [Rule], SaleTypeList, ServiceName
        FROM T_ServiceCharge_D
        WHERE EnterpriseID = @EnterpriseID
          AND ShopID = @ShopID
          AND IsUse = 1
        UNION ALL
        -- 搜尋企業服務費設定
        SELECT TOP 1 FreePercent, [Rule], SaleTypeList, ServiceName
        FROM T_ServiceCharge_D
        WHERE EnterpriseID = @EnterpriseID
          AND ShopID = (
              SELECT ParentCode
              FROM S_Organ
              WHERE EnterpriseID = @EnterpriseID
                AND OrgCode = @ShopID
          )
          AND IsUse = 1
          AND NOT EXISTS (
              SELECT 1
              FROM T_ServiceCharge_D
              WHERE EnterpriseID = @EnterpriseID
                AND ShopID = @ShopID
                AND IsUse = 1
          )
    )
    SELECT     
        (    
            SELECT     
                (    
                    SELECT     
                        Name AS [key],    
                        Value AS value    
                    FROM SettingsData    
                    WHERE SettingType = 'takeoutSettings'    
                    FOR JSON PATH    
                ) AS takeoutSettings,    
                (    
                    SELECT    
                        Name AS [key],    
                        Value AS value    
                    FROM SettingsData    
                    WHERE SettingType = 'dineInSettings'    
                    FOR JSON PATH    
                ) AS dineInSettings,    
                (    
                    SELECT    
                        Name AS [key],    
                        Value AS value    
                    FROM SettingsData    
                    WHERE SettingType = 'deliverySettings'    
                    FOR JSON PATH    
                ) AS deliverySettings,    
                (    
                    SELECT *    
                    FROM DeskData    
                    FOR JSON PATH    
                ) AS dineInTables,    
                (SELECT bannerImagePath FROM BannerData) AS bannerImagePath,    
                JSON_QUERY((    
                    SELECT     
                        ShopName,    
                        ShopID,    
                        ShopAddress,    
						ShopPhone,
                        ShopLatitude,
                        ShopLongitude   
                    FROM ShopData    
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER    
                )) AS shopInfo,    
                JSON_QUERY('{     
                  "IsEnabled": true,     
                  "InvoiceTypes": {     
                      "PERSONAL": "紙本發票",     
                      "COMPANY": "公司發票",   
                      "E_INVOICE": "電子載具",  
                      "DONATION": "捐贈發票"   
                  }     
                }') AS InvoiceSettings, 
                JSON_QUERY((
                    SELECT *
                    FROM ServiceFeeSetting
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                )) AS serviceFeeSetting 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER    
        ) AS Result    
END 
GO
