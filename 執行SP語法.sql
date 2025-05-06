-- 基本 SP 執行方式
EXEC [dbo].[sp_GetComboItems] 
    @enterpriseId = N'xurf',
    @shopId = N'A001',  
    @foodId = N'la0234037',
    @orderType = N'2',
    @langId = N'TW';