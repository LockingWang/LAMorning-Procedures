SELECT TOP (1000) [GID]
      ,[EnterpriseID]
      ,[ShopID]
      ,[AppSetting_D_GID]
      ,[Value]
      ,[ShopName]
      ,[LastOP]
      ,[LastModify]
  FROM [NCW_xurf].[dbo].[S_AppSetting_Shop]
  WHERE EnterpriseID = 'xurf'
  and ShopID = 'A001'