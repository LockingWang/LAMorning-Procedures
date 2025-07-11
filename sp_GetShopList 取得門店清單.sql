-- CREATE OR ALTER PROCEDURE [dbo].[sp_GetShopList]   
--     @enterpriseId NVARCHAR(50), -- 企業號Id   
--     @userLat FLOAT,            -- 目前位置經度   
--     @userLng FLOAT,            -- 目前位置緯度   
--     @keyword NVARCHAR(100) = NULL, -- 門市關鍵字查詢   
--     @topN INT = 1000,             -- 取N筆 (預設10筆) 
--     @modeID NVARCHAR(50) = 'takeout' -- 預設為取門店外帶設定 
-- AS   
  
DECLARE  
    @enterpriseId NVARCHAR(50) = 'XFlamorning', -- 企業號Id   
    @userLat FLOAT,            -- 目前位置經度   
    @userLng FLOAT,            -- 目前位置緯度   
    @keyword NVARCHAR(100) = NULL, -- 門市關鍵字查詢   
    @topN INT = 1000,             -- 取N筆 (預設10筆)   
	@modeID NVARCHAR(50) = 'scaneDesk' -- 預設為取門店外帶設定 
 
BEGIN   
    SET NOCOUNT ON;     
   
	SELECT TOP (@topN)   
		store.OrgCode AS ShopId,   -- 門市編號   
	    store.OrgName AS ShopName, -- 門市名稱   
	    store.Addr AS ShopAddress, -- 門市地址   
	    store.Tel AS ShopTel,      -- 門市電話 
        ISNULL((select  
            CASE  
                WHEN S.[Value] = 'true' THEN 'false' 
                WHEN S.[Value] = 'false' THEN 'true' 
            END 
            from S_AppSetting_Shop S 
            JOIN S_Appsetting_M M ON M.ModeID = @modeID 
            JOIN S_AppSetting_D D ON S.AppSetting_D_GID = D.GID AND D.AppSetting_M_GID = M.GID AND D.Name = 'IsRejectOrder' 
            WHERE EnterpriseID = @enterpriseId 
            AND ShopID = store.OrgCode), 'true') AS  AcceptAppOrder,     -- 是否接單   
	    CASE    
	        WHEN @userLat IS NOT NULL AND @userLng IS NOT NULL 
	             AND @userLat <> 0 AND @userLng <> 0
	             AND store.google_lat IS NOT NULL AND store.google_lng IS NOT NULL 
	             AND store.google_lat <> '' AND store.google_lng <> '' THEN   
	            ROUND(6371 * ACOS(COS(RADIANS(@userLat)) * COS(RADIANS(store.google_lat)) * COS(RADIANS(store.google_lng) - RADIANS(@userLng)) + SIN(RADIANS(@userLat)) * SIN(RADIANS(store.google_lat))), 2)    
	        ELSE    
	            null -- 當用戶經緯度為NULL或0時，距離顯示為NULL   
	    END AS Distance -- 計算距離 (公里)   
	FROM S_Organ store   
	WHERE store.EnterPriseID = @enterpriseid   
	  AND store.OrgType = '1' -- 取門市   
	  AND store.OrgCode <> '9999' -- OrgCode 不等於 9999(測試店)   
	ORDER BY Distance; -- 按距離排序
END