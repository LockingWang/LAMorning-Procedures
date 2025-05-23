SELECT TOP (1000) [EnterpriseID]
      ,[ShopID]
      ,[ID]
      ,[OrderID]
      ,[ItemID]
      ,[SourceKind]
      ,[AgioKind]
      ,[Owner]
      ,[AgioReason]
      ,[AgioPercent]
      ,[AgioTotal]
      ,[AgioCost]
      ,[AgioReasonName]
      ,[WorkDate]
      ,[TotalAgioPercent]
      ,[TotalAgioTotal]
      ,[TotalAgioCost]
      ,[WorkTime]
      ,[CloseMachine]
      ,[LastOP]
      ,[GroupOn_NO]
      ,[GroupOn_ID]
      ,[GroupOn_ROC]
      ,[GroupOn_Bak]
      ,[Redeemed_points]
      ,[before_points]
      ,[After_points]
      ,[Redeemed_points1]
      ,[ReasonID]
      ,[ReasonName]
      ,[TransTime]
      ,[UploadMachine]
      ,[Ag_memo]
      ,[opseg]
      ,[AgioType]
      ,[AgioGroup]
      ,[AgioServTotal]
      ,[Total]
      ,[servTotal]
      ,[subTotal]
      ,[LastModify]
  FROM [NCW_xurf].[dbo].[P_AgioTemp_Web]
  where EnterpriseID = 'xurf'