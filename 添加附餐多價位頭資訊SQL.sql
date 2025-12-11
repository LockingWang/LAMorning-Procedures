-- 附餐不會有 PriceExpr 欄位，所以要去 P_Food 找

SELECT 
  food.PriceExpr,* 
FROM P_FoodEnt_Mould ent
LEFT JOIN P_Food food ON food.ID = ent.EntFood and food.EnterpriseID = ent.EnterpriseID -- JOIN 多價位附餐的主檔資訊
WHERE ent.EnterpriseID = 'XF93610935'
AND food.PriceExpr <> '1' AND food.PriceExpr <> '' -- 篩選附餐多價位子項目
AND (
    select 1 from P_FoodEnt_Mould ent2
    where ent2.EntFood = food.PriceExpr
    and ent2.MainFood = ent.MainFood
    and ent2.MouldCode = ent.MouldCode
)
