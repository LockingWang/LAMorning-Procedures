SELECT TOP (1000) [GID]
      ,[EnterpriseID]
      ,[ID]
      ,[AI_No]
      ,[AgioKind]
      ,[Name]
      ,[DiscountKind]
      ,[DiscountValue]
      ,[effective_from]
      ,[effective_to]
      ,[Week1]
      ,[Week2]
      ,[Week3]
      ,[Week4]
      ,[Week5]
      ,[Week6]
      ,[Week7]
      ,[LastModify]
      ,[LastOP]
      ,[IsVIP]
      ,[VIPKind]
      ,[AI_Memo]
      ,[AI_StartTime]
      ,[AI_EndTime]
      ,[AutoSvc]
      ,[AgioSlt]
      ,[AgioGrade]
      ,[MaxAgio]
      ,[MinAgio]
      ,[MaxAgioCost]
      ,[MinAgioCost]
      ,[Kind]
      ,[Points]
  FROM [NCW_xurf].[dbo].[P_AgioItems]
  WHERE Name = '20250506測試優惠1'