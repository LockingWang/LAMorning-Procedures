SELECT TOP (1000) [GID]
      ,[EnterPriseID]
      ,[MouldCode]
      ,[ShopID]
      ,[ShopName]
      ,[LastOp]
      ,[LastModify]
  FROM [NCW_xurf].[dbo].[P_FoodMould_Shop]
  WHERE EnterPriseID = '90367984' AND MouldCode = 'OnlineQRCode_TESTlamorning'