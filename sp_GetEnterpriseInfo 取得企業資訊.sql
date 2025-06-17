CREATE PROCEDURE [dbo].[sp_GetEnterpriseInfo] 
    @enterpriseId NVARCHAR(50) -- 企業號Id 
AS 
BEGIN 
    SET NOCOUNT ON; 
--     
--    SELECT 
--		    '' AS EnterpriseName,      -- 品牌名稱 
--        '' AS LogoLarge,           -- 品牌Logo(大) 
--        '' AS LogoSmall,           -- 品牌Logo(小) 
--        '' AS PrimaryColor,        -- 主要色 
--        '' AS SecondaryColor,      -- 輔助色 
--        NULL AS AccentColor,         -- 強調色 
--        NULL AS TertiaryColor,       -- 第三色 
--        NULL AS PrimaryButtonColor,      -- 主要按鈕顏色 
--        NULL AS PrimaryButtonTextColor,  -- 主要按鈕文字顏色 
--        NULL AS SecondaryButtonColor,    -- 次要按鈕顏色 
--        NULL AS SecondaryButtonTextColor, -- 次要按鈕文字顏色 
--        '' AS CustomerServicePhone     -- 客服專線 
         
    SELECT  
	    -- 提取品牌Logo資訊 
    	se.EnterpriseName AS EnterpriseName, 
	    JSON_VALUE(config, '$.logoRectangle') AS LogoLarge, 
	    JSON_VALUE(config, '$.logoSquare') AS LogoSmall, 
	     
	    -- 提取顏色配置資訊 
	    JSON_VALUE(config, '$.colorPrimary') AS PrimaryColor, 
	    JSON_VALUE(config, '$.colorSub') AS SecondaryColor, 
	    JSON_VALUE(config, '$.colorAccent') AS AccentColor, 
	    JSON_VALUE(config, '$.colorThird') AS TertiaryColor, 
	    JSON_VALUE(config, '$.colorPrimary') AS PrimaryButtonColor, 
	    JSON_VALUE(config, '$.colorButtonText') AS PrimaryButtonTextColor, 
	    JSON_VALUE(config, '$.colorPrimary') AS SecondaryButtonColor, 
	    JSON_VALUE(config, '$.colorSecondaryButtonText') AS SecondaryButtonTextColor, 
	     
	    -- 取得客服專線 (當 S_Organ 表的 EnterPriseID = OrgCode = 企業號Id) 
	    (SELECT Tel FROM NCW_xurf.dbo.S_Organ  
	     WHERE EnterPriseID = @enterpriseid AND OrgCode = @enterpriseid) AS CustomerServicePhone 
	FROM NCW_xurf.dbo.System_Enterprise se 
	LEFT JOIN NCW_xurf.dbo.T_SystemSetting ts ON se.EnterpriseID = ts.EnterpriseID 
	WHERE se.EnterpriseID = @enterpriseid; 
 
END