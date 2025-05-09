-- <functionGroup>sp_OnlineOrder</functionGroup> 
CREATE   PROCEDURE [dbo].[sp_GetShopInfo2] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @shopId NVARCHAR(50)        -- 門市Id 
AS 
BEGIN 
    SET NOCOUNT ON; 
     
    SELECT DISTINCT 
    banner.dir AS BannerImagePath, 
    b.shopname AS StoreName, 
    store.Addr AS StoreAddress, 
    IsRej.DefaultValue AS StoreStatus, 
    CURRENT_TIMESTAMP-BookAdv.DefaultValue+ArrivT.DefaultValue AS MinDeliveryTime, 
    --timeinf.DefaultValue AS OrderTimeRanges, 
		'[ 
       { 
            "Week": 1, 
            "StartTime": "10:00:00", 
            "EndTime": "17:00:00" 
        } 
    ]' AS OrderTimeRanges, 
    OrdDist.DefaultValue AS OrderDistanceLimit, 
    OrdMemo.DefaultValue AS OrderInstructions, 
    ( 
        SELECT JSON_QUERY( 
            (SELECT 
                CAST(1 AS Bit) AS IsEnabled, 
                ( 
                    SELECT  
                        '' AS Id, 
                        desk.name AS Name, 
                        desk.SeatNum AS Capacity 
                    FROM T_DESK desk 
                    WHERE desk.enterpriseid = @enterpriseid AND desk.shopid = @ShopID 
                    FOR JSON PATH 
                ) AS Tables, 
                JSON_QUERY(paytype.DefaultValue) AS PaymentMethods 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) 
        ) 
    ) AS DineInSettings, 
 JSON_QUERY( 
        (SELECT 
            CAST(1 AS Bit) AS IsEnabled, 
            JSON_QUERY(paytype.DefaultValue) AS PaymentMethods 
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) 
    ) AS DeliverySettings, 
 JSON_QUERY( 
        (SELECT 
            CAST(1 AS Bit) AS IsEnabled, 
    JSON_QUERY(paytype.DefaultValue) AS PaymentMethods 
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) 
    )    AS TakeoutSettings, 
    '{ 
        "IsEnabled": true, 
        "InvoiceTypes": { 
            "PERSONAL": "個人發票", 
            "COMPANY": "公司發票", 
            "DONATION": "捐贈發票" 
        } 
    }' AS InvoiceSettings, 
       NULL AS OrderNotes              -- 訂單備註 
 --   uniform.DefaultValue AS uniform, 
 --   store.City 
FROM  
    S_Organ store 
    JOIN S_AppSetting_Shop b ON b.shopID = store.OrgCode AND b.enterpriseid = store.EnterPriseID 
    JOIN S_UploadFile banner ON banner.vType = 'E_Banner'  
    JOIN S_AppSetting_D D ON D.GID = b.AppSetting_D_GID 
    JOIN S_Appsetting_M m ON M.GID = D.AppSetting_M_GID AND m.modeid = 'delivery' 
    LEFT JOIN S_AppSetting_D IsRej ON IsRej.gid = D.GID AND IsRej.Name = 'IsRejectOrdr' 
    LEFT JOIN S_AppSetting_D BookAdv ON BookAdv.gid = D.GID AND BookAdv.Name = 'BoodInAdvance' 
    LEFT JOIN S_AppSetting_D ArrivT ON ArrivT.gid = D.gid AND Arrivt.Name = 'SendTime' 
    LEFT JOIN S_AppSetting_D OrdMemo ON OrdMemo.gid = D.gid AND OrdMemo.Name = 'OrderInstructions' 
    LEFT JOIN S_AppSetting_D OrdDist ON OrdDist.gid = D.gid AND OrdDist.Name = 'kmRange' 
    LEFT JOIN S_AppSetting_D timeinf ON timeinf.gid = D.gid AND timeinf.Name = 'timeInfo' 
    LEFT JOIN S_AppSetting_D paytype ON paytype.gid = D.gid AND paytype.Name = 'payType' 
    LEFT JOIN S_AppSetting_D uniform ON uniform.gid = D.gid AND uniform.Name = 'IsShowInvoiceInfo' 
WHERE  
    b.EnterpriseID = @enterpriseid 
    AND b.ShopID = @ShopID; 
 
END