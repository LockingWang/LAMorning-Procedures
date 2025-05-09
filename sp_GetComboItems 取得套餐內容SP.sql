CREATE  or ALTER  PROCEDURE sp_GetComboItems  
@enterpriseId NVARCHAR(50),  
@shopId NVARCHAR(50),  
@foodId NVARCHAR(50),  
@orderType NVARCHAR(50),  
@langId varchar(10)  
AS  
BEGIN  
SET NOCOUNT ON;  
SELECT DISTINCT  
    PDK.ID AS ItemId,  
    ISNULL(JSON_VALUE(LANGKIND.Content, '$.' + @langId + '.Name'), PDK.Name) AS ItemName,  
    (  
        SELECT DISTINCT   
            ENT.EntFood AS FoodId,  
            ISNULL(SUF.Dir, '') AS ImagePath,  
            ISNULL(JSON_VALUE(LANGFOOD.Content, '$.' + @langId + '.Name'), M.Name) AS FoodName,  
            PF.Introduce AS Description,  
            ENT.Price AS Price,  
            ENT.EntNo AS Sort,  
            CAST(CASE WHEN M.Stop = 0 THEN 1 ELSE 0 END AS BIT) AS IsSoldOut  
        FROM P_FOODENT ENT  
        JOIN P_FoodMould M  
            ON ENT.EnterpriseID = M.EnterpriseID  
            AND ENT.EntFood = M.ID  
        JOIN P_Food PF  
            ON ENT.EnterpriseID = PF.EnterpriseID  
            AND ENT.EntFood = PF.ID  
        LEFT JOIN S_UploadFile SUF  
            ON ENT.EnterpriseID = SUF.EnterpriseID  
            AND SUF.ItemID = ENT.EntFood 
            AND SUF.vType = 'food2' 
        LEFT JOIN P_Data_Language_D LANGFOOD   
            ON LANGFOOD.EnterpriseID = @enterpriseid   
            AND LANGFOOD.SourceID = M.ID  
            AND LANGFOOD.TableName = 'Food'  
        WHERE ENT.EnterpriseID = @enterpriseId  
            AND ENT.MainFood = @foodId  
            AND M.Kind = PDK.ID   
            AND ENT.EntFood IS NOT NULL  
        ORDER BY ENT.EntNo  
        FOR JSON PATH  
    ) AS FoodItems,  
    1 AS MinSelectCount,  
    PEK.MaxCount AS MaxSelectCount,  
    PEK.EntKindNo AS Sort  
FROM   
    P_FOODENT PENT  
JOIN P_FoodEntKind PEK ON PEK.EnterpriseID = @enterpriseId AND PENT.MainFood = PEK.FoodID  
JOIN P_FoodKind PDK ON PDK.EnterpriseID = @enterpriseId AND PEK.KindID = PDK.ID  
JOIN P_FOOD PD ON PD.EnterpriseID = @enterpriseId AND PENT.MainFood = PD.ID  
JOIN P_FoodMould FP ON FP.EnterpriseID = @enterpriseId AND PD.ID = FP.ID  
JOIN P_FoodMould_M fm ON fm.EnterpriseID = @enterpriseId AND FP.MouldCode = fm.MouldCode  
JOIN P_FoodMould_Shop fshop ON fshop.EnterpriseID = @enterpriseId AND fm.MouldCode = fshop.MouldCode  
JOIN P_FoodKind_Mould K1
    ON K1.EnterpriseID = @enterpriseId  
    AND K1.MouldCode = fm.MouldCode  
    AND k1.id = fp.kind  
JOIN p_foodkind2 K2   
    ON K2.EnterpriseID = @enterpriseId
    AND K2.ID = FP.kind2  
    AND k2.id = k1.FLevel  
LEFT JOIN P_Data_Language_D LANGKIND  
    ON LANGKIND.EnterpriseID = @enterpriseid   
    AND LANGKIND.SourceID = PDK.ID   
    AND LANGKIND.TableName = 'FoodKind'  
WHERE   
    PENT.EnterpriseID = @enterpriseId
    AND PENT.MainFood = @foodId
    AND fshop.shopid = @shopId
    AND fm.status = 9
    AND fm.MouldType = CASE @orderType
        WHEN 'takeout' THEN 2
        WHEN 'delivery' THEN 5
        WHEN 'scaneDesk' THEN 6
    END 
ORDER BY PEK.EntKindNo;  
END