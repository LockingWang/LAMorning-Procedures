SELECT 
    t1.GID,
    t1.EnterPriseID,
    t1.CardTypeCode1,
    t1.CardTypeCode2, 
    t1.Days,
    t1.CumulativeSales,
    t1.CumulativeBalance,
    t1.TradeRuleCode,
    t1.Remarks,
    t1.CardTypeName1,
    t2.CardTypeName AS CardTypeName2
FROM (
    SELECT 
        a.*,
        b.CardTypeName AS CardTypeName1
    FROM VIP_CardUpgradeRules AS a
    INNER JOIN VIP_CardType AS b 
        ON a.EnterPriseID = b.EnterPriseID 
        AND a.CardTypeCode1 = b.CardTypeCode
    WHERE a.EnterPriseID = :EnterPriseID
) AS t1
INNER JOIN VIP_CardType t2
    ON t1.EnterPriseID = t2.EnterPriseID 
    AND t1.CardTypeCode2 = t2.CardTypeCode