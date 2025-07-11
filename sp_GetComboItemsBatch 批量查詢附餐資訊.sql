CREATE OR ALTER PROCEDURE [dbo].[sp_GetComboItemsBatch]  
    @enterpriseId NVARCHAR(50),  
    @shopId NVARCHAR(50),  
    @foodIds NVARCHAR(MAX),  
    @orderType NVARCHAR(50),  
    @langId NVARCHAR(50)  
AS  
 
-- DECLARE @enterpriseId NVARCHAR(50) = '90367984',  
--     @shopId NVARCHAR(50) = 'A01',  
--     @foodIds NVARCHAR(MAX) = 'Mp34699',  
--     @orderType NVARCHAR(50) = 'scaneDesk',  
--     @langId NVARCHAR(50) = 'TW'; 
 
BEGIN  
    SET NOCOUNT ON;  
      
    -- 將逗號分隔的 foodIds 轉換為表格  
    DECLARE @FoodIdsTable TABLE (FoodId NVARCHAR(50))  
    INSERT INTO @FoodIdsTable  
    SELECT value FROM STRING_SPLIT(@foodIds, ',')  
  
    SELECT  
        F.FoodId, 
        PEK.KindID AS ItemId, 
        ISNULL(JSON_VALUE(LANGKIND.Content, '$.' + @langId + '.Name'), PEK.KindName) AS ItemName,  
        -- 取得附餐資訊 
        (  
            SELECT DISTINCT  
                ENT.EntFood AS FoodId, 
                ISNULL(JSON_VALUE(LANGFOOD.Content, '$.' + @langId + '.Name'), PF.Name) AS FoodName, 
                ISNULL(SUF.Dir, '') AS ImagePath,  
                PF.Introduce AS Description, 
                ENT.Price AS Price, 
                ENT.EntNo AS Sort, 
                ISNULL(PFMJ.Stop,0) AS IsSoldOut, 
                CAST(CASE WHEN PF.Hide = 1 THEN 1 ELSE 0 END AS BIT) AS IsHidden, 
                ENT.Auto AS IsAutoSelected, 
                ENT.Def AS IsDefaultSelected 
            FROM P_FoodEnt_Mould ENT 
            JOIN P_FoodMould PF 
                ON ENT.EnterpriseID = PF.EnterpriseID 
                AND ENT.EntFood = PF.ID 
                AND PF.MouldCode = fm.MouldCode 
                AND PF.Kind = PEK.KindID
                AND (PF.Stop = 0 OR PF.Stop IS NULL)
            LEFT JOIN S_UploadFile SUF 
                ON ENT.EnterpriseID = SUF.EnterpriseID 
                AND SUF.ItemID = ENT.EntFood  
                AND SUF.vType = 'food2'  
            LEFT JOIN P_Data_Language_D LANGFOOD  
                ON LANGFOOD.EnterpriseID = @enterpriseid  
                AND LANGFOOD.SourceID = ENT.EntFood 
                AND LANGFOOD.TableName = 'Food'
            -- POS 商品售完 
            LEFT JOIN P_FoodMouldJoin PFMJ on PFMJ.EnterpriseID = @enterpriseId and PFMJ.MouldCode = fm.MouldCode and PFMJ.FoodID = ENT.EntFood and PFMJ.ShopID = @shopId
            WHERE ENT.EnterpriseID = @enterpriseId  
                AND ENT.MainFood = F.FoodId 
                AND ENT.MouldCode = fm.MouldCode 
                AND ENT.EntFood IS NOT NULL  
            ORDER BY ENT.EntNo  
            FOR JSON PATH  
        ) AS FoodItems,  
        PEK.MaxCount AS MaxSelectCount,  
        PEK.MinCount AS MinSelectCount,  
        PEK.EntKindNo AS Sort  
    FROM @FoodIdsTable F 
    -- 先透過 P_FoodMould_M 以及 P_FoodMould_Shop 確定要取的菜單 MouldCode 
    JOIN P_FoodMould_M fm ON fm.EnterpriseID = @enterpriseId 
        AND fm.[Status] = 9 
        AND fm.MouldType = CASE @orderType        
            WHEN 'takeout' THEN 2        
            WHEN 'delivery' THEN 5         
            WHEN 'scaneDesk' THEN 6        
        END  
    JOIN P_FoodMould_Shop fshop ON fshop.EnterpriseID = @enterpriseId AND fshop.ShopID = @shopId AND fm.MouldCode = fshop.MouldCode 
    -- 取得*小類*的資訊與數量設定 
    JOIN P_FoodEntKind_Mould PEK ON PEK.EnterpriseID = @enterpriseId AND PEK.MouldCode = fm.MouldCode AND PEK.FoodID = F.FoodId 
    LEFT JOIN P_Data_Language_D LANGKIND 
        ON LANGKIND.EnterpriseID = @enterpriseid 
        AND LANGKIND.SourceID = PEK.KindID 
        AND LANGKIND.TableName = 'FoodKind'  
    ORDER BY F.FoodId, PEK.EntKindNo  
END