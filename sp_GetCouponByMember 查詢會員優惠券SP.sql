CREATE OR ALTER PROCEDURE [dbo].[sp_GetCouponByMember]  
    @enterpriseId NVARCHAR(50),  
    @shopId NVARCHAR(50),  
    @memberNo VARCHAR(50)  
AS  
  
-- 測試用  
-- DECLARE @enterpriseId NVARCHAR(50) = '90367984'  
-- DECLARE @shopId NVARCHAR(50) = 'A01'  
-- DECLARE @memberNo NVARCHAR(50) = '0975011014'  
  
BEGIN  
    SET NOCOUNT ON;  
  
    SELECT   
        V_TI.CardTradeNum, -- 批次交易號碼  
        V_TI.TicketInfoID, -- 優惠券資料ID
        V_TI.TicketTypeCode, -- 優惠券代碼  
        V_TI.TicketCount, -- 優惠券張數
        V_TI.TicketExpiredDate, -- 有效期限  
  
        V_TT.TicketTypeName, -- 優惠卷名稱  
        V_TT.TicketFlag, -- 優惠卷類型(現金券、折扣券...)  
        V_TT.TicketPrice, -- 優惠券額度  
        V_TT.TicketDiscount, -- 優惠券折數  
        V_TT.Remark, -- 優惠卷說明  
        V_TT.PicUrl, -- 優惠券圖片  
  
        V_TR.BeginDate, -- 最早可使用日  
        V_TR.EndDate ,  -- 有效日期結束日  
        V_TR.BeginTime , -- 可用時段(開始)  
        V_TR.EndTime , -- 可用時段(結束)  
        V_TR.Week1, -- 星期一可否使用  
        V_TR.Week2, -- 星期二可否使用  
        V_TR.Week3, -- 星期三可否使用  
        V_TR.Week4, -- 星期四可否使用  
        V_TR.Week5, -- 星期五可否使用  
        V_TR.Week6, -- 星期六可否使用  
        V_TR.Week7, -- 星期日可否使用  
        (SELECT JSON_QUERY('[' + STRING_AGG('"' + ShopID + '"', ',') + ']')  
         FROM VIP_TradeRuleShops V_TRS   
         WHERE V_TRS.EnterPriseID = @enterpriseId   
         AND V_TRS.TradeRuleCode = V_TR.TradeRuleCode) AS shopList,  
        (SELECT JSON_QUERY('[' + STRING_AGG('"' + FoodID + '"', ',') + ']')  
         FROM VIP_TradeRules_Food V_TR_F   
         WHERE V_TR_F.EnterPriseID = @enterpriseId   
         AND V_TR_F.TradeRuleCode = V_TR.TradeRuleCode) AS foodList  
  
    FROM VIP_TicketInfo V_TI  
    JOIN VIP_TicketType V_TT ON V_TT.EnterPriseID = @enterpriseId AND V_TT.TicketTypeCode = V_TI.TicketTypeCode  
    LEFT JOIN VIP_TradeRules V_TR ON V_TR.EnterPriseID = @enterpriseId AND V_TR.CardTypeCode  = V_TI.TicketTypeCode  
    -- LEFT JOIN VIP_TradeRuleShops V_TRS ON V_TRS.EnterPriseID = @enterpriseId AND V_TRS.TradeRuleCode =  V_TR.TradeRuleCode  
    -- LEFT JOIN VIP_TradeRules_Food V_TR_F ON V_TR_F.EnterPriseID = @enterpriseId AND V_TR_F.TradeRuleCode =  V_TR.TradeRuleCode  
    WHERE V_TI.EnterPriseID = @enterpriseId  
    AND V_TI.MemberNO = @memberNo  
    AND V_TI.TicketCount > 0
    AND V_TI.TicketExpiredDate >= CAST(GETDATE() AS DATE)
    ORDER BY V_TI.TicketExpiredDate ASC
END