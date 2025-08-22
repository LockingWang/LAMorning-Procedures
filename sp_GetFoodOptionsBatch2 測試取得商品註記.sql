SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_GetFoodOptionsBatch2]      
    @enterpriseId NVARCHAR(50),      
    @shopId NVARCHAR(50),      
    @foodIds NVARCHAR(MAX),      
    @langId NVARCHAR(50),
    @mouldCodes NVARCHAR(MAX)      -- 菜單代碼清單（逗號分隔）
AS        
  
-- DECLARE      
--     @enterpriseId NVARCHAR(50) = 'xurf',       
--     @shopId NVARCHAR(50) = 'A001',     
--     @foodIds NVARCHAR(MAX) = 'la0134036',     
--     @langId NVARCHAR(50) = 'TW',
--     @mouldCodes NVARCHAR(MAX) = 'MENU001,MENU002';       
     
     
BEGIN      
    SET NOCOUNT ON;      
        
    -- 將逗號分隔的 mouldCodes 轉換為表格    
    DECLARE @MouldCodesTable TABLE (MouldCode NVARCHAR(50))    
    INSERT INTO @MouldCodesTable    
    SELECT value FROM STRING_SPLIT(@mouldCodes, ',')    
          
    -- 將逗號分隔的 foodIds 轉換為表格      
    DECLARE @FoodIdsTable TABLE (FoodId NVARCHAR(50), FoodKind NVARCHAR(50))      
    INSERT INTO @FoodIdsTable (FoodId, FoodKind)     
    SELECT value, NULL FROM STRING_SPLIT(@foodIds, ',')      
     
    -- 根據 FoodId 更新 FoodKind 
    UPDATE F 
    SET F.FoodKind = PFM.Kind 
    FROM @FoodIdsTable F 
    JOIN P_FoodMould PFM ON PFM.EnterpriseID = @enterpriseId 
        AND PFM.MouldCode IN (SELECT MouldCode FROM @MouldCodesTable)
        AND PFM.ID = F.FoodId
    JOIN P_Food PF ON PF.enterpriseID = @enterpriseId 
        AND PF.Kind = PFM.Kind 
        AND PF.ID = F.FoodId 
        AND PF.NoKindAdd = '0'
  
    SELECT      
        F.FoodId,    
        FAK.ID AS ItemId,      
        ISNULL(JSON_VALUE(LANGKIND.Content, '$.' + @langId + '.Name'), FAK.Name) AS ItemName,      
        (      
            SELECT      
                CAST(FA2.ID AS NVARCHAR(50)) AS FoodId,      
                '' AS ImagePath,      
                ISNULL(JSON_VALUE(LANGADD.Content, '$.' + @langId + '.Name'), FA2.Name) AS FoodName,      
                '' AS Description,      
                FA2.Price,      
                FA2.SN AS Sort,      
                ISNULL(PFMJ.Stop,0) AS IsSoldOut,   
                FA2.Lock   
            FROM P_FoodAdd_Mould FA2  
            LEFT JOIN P_Data_Language_D LANGADD      
                ON LANGADD.EnterpriseID = @enterpriseid      
                AND LANGADD.SourceID = FA2.ID      
                AND LANGADD.TableName = 'FoodAdd'    
            LEFT JOIN P_FoodTasteAddMouldJoin PFMJ on PFMJ.EnterpriseID = @enterpriseId and PFMJ.TasteAddName = FA2.Name and PFMJ.ShopID = @shopId    
            WHERE FA2.AddKindID = FAK.ID      
            AND FA2.EnterpriseID = @enterpriseId      
            AND (FA2.Owner = F.FoodId OR FA2.[Owner] = F.FoodKind) 
            AND FA2.MouldCode IN (SELECT MouldCode FROM @MouldCodesTable)
            ORDER BY FA2.SN      
            FOR JSON PATH      
        ) AS Items,      
        FAK.needed AS MinSelectCount,    
        FAK.MaxCount AS MaxSelectCount    
    FROM @FoodIdsTable F    
    JOIN P_FoodAdd_Mould FAM ON FAM.EnterpriseID = @enterpriseId 
        AND FAM.MouldCode IN (SELECT MouldCode FROM @MouldCodesTable)    
    JOIN P_FoodAddKind FAK ON FAK.ID = FAM.AddKindID    
    -- 依據語系找出對應的顯示文字    
    LEFT JOIN P_Data_Language_D LANGKIND      
        ON LANGKIND.EnterpriseID = @enterpriseid      
        AND LANGKIND.SourceID = FAK.ID      
        AND LANGKIND.TableName = 'FoodAddKind'  
    WHERE (FAM.Owner = F.FoodId OR FAM.[Owner] = F.FoodKind)
        AND F.FoodKind IS NOT NULL  -- 只查詢已成功更新 FoodKind 的食品
    GROUP BY F.FoodId, F.FoodKind ,FAK.ID,FAK.SN, FAK.Name, FAK.MaxCount, FAK.needed, LANGKIND.Content
    order by FAK.SN
END
GO
