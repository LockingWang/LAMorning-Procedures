SELECT TOP (1000) [GID]
      ,[EnterPriseID]
      ,[ParameterGID]
      ,[ParameterValue]
      ,[LastOP]
      ,[LastModify]
  FROM [NCW_xurf].[dbo].[S_Parameter_Enterprise]
WHERE EnterPriseID = 'Xurf'
and ParameterGID = '79dabbec-a224-4f34-a13e-04540c9d548e'