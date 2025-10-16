SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_GetEnterpriseInfo] 
    @enterpriseId NVARCHAR(50) -- 企業號Id 
AS 

-- DECLARE @enterpriseId NVARCHAR(50) = 'Xurf' -- 企業號Id 

BEGIN 
    SET NOCOUNT ON; 
         
    SELECT  
	    -- 提取品牌Logo資訊 
    	so.OrgName AS EnterpriseName, 
        so.Tel AS CustomerServicePhone,
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

        -- 取得 AppSMSDayTimes 參數
	    (SELECT ISNULL(pe.ParameterValue, ps.ParameterValue)
	     FROM S_Parameter_System ps
	     LEFT JOIN S_Parameter_Enterprise pe
	         ON pe.ParameterGID = ps.GID
	         AND pe.EnterPriseID = @enterpriseId
	     WHERE ps.ParameterName = 'AppSMSDayTimes') AS AppSMSDayTimes,
	     
	    -- 取得AppSMSIntervalMin參數
	    (SELECT ISNULL(pe.ParameterValue, ps.ParameterValue) AS AppSMSIntervalMin
	     FROM S_Parameter_System ps
	     LEFT JOIN S_Parameter_Enterprise pe
	         ON pe.ParameterGID = ps.GID
	         AND pe.EnterPriseID = @enterpriseId
	     WHERE ps.ParameterName = 'AppSMSIntervalMin') AS AppSMSIntervalMin 
	FROM System_Enterprise se 
	LEFT JOIN T_SystemSetting ts ON ts.EnterpriseID = @enterpriseId AND ts.OrgCode = @enterpriseId
	LEFT JOIN S_Organ so on so.EnterPriseID=@enterpriseId and so.OrgType=5 and so.OrgCode=@enterpriseId -- 企業名稱改為抓S_Organ避免修改後顯示錯誤
	WHERE se.EnterpriseID = @enterpriseid;
 
END
GO
