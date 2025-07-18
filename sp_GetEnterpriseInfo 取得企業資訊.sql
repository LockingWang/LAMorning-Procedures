CREATE   PROCEDURE [dbo].[sp_GetEnterpriseInfo]  
    @enterpriseId NVARCHAR(50) -- 企業號Id  
AS  
 
-- DECLARE @enterpriseId NVARCHAR(50) = 'xurf' -- 企業號Id  
 
BEGIN  
    SET NOCOUNT ON;  
          
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
	LEFT JOIN NCW_xurf.dbo.T_SystemSetting ts ON ts.EnterpriseID = @enterpriseId AND ts.OrgCode = @enterpriseId 
	WHERE se.EnterpriseID = @enterpriseid;  
  
END