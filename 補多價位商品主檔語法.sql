SELECT DISTINCT 
    f1.PriceExpr,
    food.Name,
    f1.EnterpriseID, 
    f1.MouldCode,
    mould.MouldName,
    mould.MouldType,
    mould.[Status]
FROM P_FoodMould f1

LEFT JOIN P_Food food ON food.EnterpriseID = f1.EnterpriseID AND food.ID = f1.PriceExpr
LEFT JOIN P_FoodMould_M mould ON mould.EnterpriseID = f1.EnterpriseID AND mould.MouldCode = f1.MouldCode

WHERE f1.PriceExpr <> '' 
    AND f1.PriceExpr <> '1'
    AND EXISTS (
        SELECT 1 
        FROM P_Food food_check
        WHERE food_check.EnterpriseID = f1.EnterpriseID
        AND food_check.ID = f1.ID
    )
    AND EXISTS (
        SELECT 1 
        FROM P_Food food_check2
        WHERE food_check2.EnterpriseID = f1.EnterpriseID
        AND food_check2.ID = f1.PriceExpr
    )
    AND NOT EXISTS (
        SELECT 1 
        FROM P_FoodMould f2
        WHERE f2.EnterpriseID = f1.EnterpriseID
        AND f2.MouldCode = f1.MouldCode
        AND f2.ID = f1.PriceExpr
    )
    AND mould.[Status] = '9'
    AND mould.MouldType IN ('2','3','5','6')