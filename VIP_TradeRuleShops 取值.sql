SELECT TOP (1000) [GID]
      ,[LastOP]
      ,[LastModify]
      ,[EnterPriseID]
      ,[TradeRuleCode]
      ,[ShopID]
      ,[ShopName]
  FROM [NCW_xurf].[dbo].[VIP_TradeRuleShops]
  WHERE EnterPriseID = 'xurf' AND TradeRuleCode = 'dfjfne'