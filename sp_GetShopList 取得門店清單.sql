CREATE PROCEDURE [dbo].[sp_GetShopList]  
    @enterpriseId NVARCHAR(50), -- 企業號Id  
    @userLat FLOAT,            -- 目前位置經度  
    @userLng FLOAT,            -- 目前位置緯度  
    @keyword NVARCHAR(100) = NULL, -- 門市關鍵字查詢  
    @topN INT = 10             -- 取N筆 (預設10筆)  
AS  
BEGIN  
    SET NOCOUNT ON;  
      
--    SELECT TOP (@topN)  
--				'A02' AS shopId, -- 門市Id  
--        '惠饗製研所' AS ShopName,           -- 門市名稱  
--        '台北市信義區永吉路302號2樓之1' AS ShopAddress,        -- 門市地址  
--        1.55 AS Distance,           -- 距離 (KM)  
--        CAST(1 AS Bit) AS AcceptAppOrder        -- 是否接受APP訂單  
  
	SELECT DISTINCT TOP (@topN)  
		store.OrgCode AS ShopId,	--門市編號  
	    store.OrgName AS ShopName, -- 門市名稱  
	    store.Addr AS ShopAddress, -- 門市地址  
	    store.Tel AS ShopTel,      -- 門市電話 
	    CASE   
	        WHEN IsRej.DefaultValue = 'true' THEN 0  
	        ELSE 1  
	    END AS AcceptAppOrder, -- 是否接受訂單  
	    CASE   
	        WHEN store.google_lat IS NOT NULL AND store.google_lng IS NOT NULL AND store.google_lat <> '' AND store.google_lng <> '' THEN  
	            ROUND(6371 * ACOS(COS(RADIANS(@userLat)) * COS(RADIANS(store.google_lat)) * COS(RADIANS(store.google_lng) - RADIANS(@userLng)) + SIN(RADIANS(@userLat)) * SIN(RADIANS(store.google_lat))), 2)   
	        ELSE   
	            9999 -- 顯示 9999  
	    END AS DistanceKM -- 計算距離 (公里)  
	FROM S_Organ store  
	LEFT JOIN S_AppSetting_Shop b ON b.enterpriseid = store.EnterPriseID AND b.shopID = store.OrgCode  
	LEFT JOIN S_AppSetting_D D ON b.AppSetting_D_GID = D.GID  
	LEFT JOIN S_AppSetting_D IsRej ON IsRej.gid = D.GID AND IsRej.Name = 'IsRejectOrdr'  
	WHERE store.EnterPriseID = @enterpriseid  
	  AND store.OrgType = '1' -- OrgType = 1  
	  AND store.OrgCode <> '9999' -- OrgCode 不等於 9999  
	ORDER BY DistanceKM; -- 按距離排序  
  
END 