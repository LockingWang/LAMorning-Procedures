SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_GetComboItemsBatch2]    
    @enterpriseId NVARCHAR(50),    
    @shopId NVARCHAR(50),    
    @foodIds NVARCHAR(MAX),    
    @langId NVARCHAR(50),
    @mouldCodes NVARCHAR(MAX)      -- 菜單代碼清單（逗號分隔）
AS    
   
-- DECLARE @enterpriseId NVARCHAR(50) = 'XFlamorning',    
--     @shopId NVARCHAR(50) = '03F03',    
--     @foodIds NVARCHAR(MAX) = 'A5648912',    
--     @langId NVARCHAR(50) = 'TW',
--     @mouldCodes NVARCHAR(MAX) = 'OnlineTogo_A1140801';   
   
BEGIN    
    SET NOCOUNT ON;    
        
    -- 將逗號分隔的 mouldCodes 轉換為表格    
    DECLARE @MouldCodesTable TABLE (MouldCode NVARCHAR(50))    
    INSERT INTO @MouldCodesTable    
    SELECT value FROM STRING_SPLIT(@mouldCodes, ',')    
        
    -- 將逗號分隔的 foodIds 轉換為表格    
    DECLARE @FoodIdsTable TABLE (FoodId NVARCHAR(50))    
    INSERT INTO @FoodIdsTable    
    SELECT value FROM STRING_SPLIT(@foodIds, ',')    
    
    SELECT    
        F.FoodId,   
        PEK.KindID AS ItemId,
        ISNULL(JSON_VALUE(LANGKIND.Content, '$.' + @langId + '.Name'), PFK.Name) AS ItemName,    
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
                AND PF.MouldCode = ENT.MouldCode   
                AND PF.Kind = PEK.KindID  
                AND (PF.Stop = 0 OR PF.Stop IS NULL)  
            OUTER APPLY (
                SELECT TOP 1 SUF.Dir
                FROM S_UploadFile SUF
                WHERE SUF.EnterpriseID = ENT.EnterpriseID
                AND SUF.ItemID = ENT.EntFood
                AND SUF.vType = 'food2'
                ORDER BY SUF.LastModify DESC
            ) SUF
            LEFT JOIN P_Data_Language_D LANGFOOD    
                ON LANGFOOD.EnterpriseID = @enterpriseid    
                AND LANGFOOD.SourceID = ENT.EntFood   
                AND LANGFOOD.TableName = 'Food'  
            -- POS 商品售完   
            LEFT JOIN P_FoodMouldJoin PFMJ on PFMJ.EnterpriseID = @enterpriseId and PFMJ.MouldCode = ENT.MouldCode and PFMJ.FoodID = ENT.EntFood and PFMJ.ShopID = @shopId  
            WHERE ENT.EnterpriseID = @enterpriseId    
                AND ENT.MainFood = F.FoodId   
                AND ENT.MouldCode IN (SELECT MouldCode FROM @MouldCodesTable)   
                AND ENT.EntFood IS NOT NULL    
            ORDER BY ENT.EntNo    
            FOR JSON PATH    
        ) AS FoodItems,    
        PEK.MaxCount AS MaxSelectCount,    
        PEK.MinCount AS MinSelectCount,    
        PEK.EntKindNo AS Sort, 
        PEK.[Group] AS [Group] 
    FROM @FoodIdsTable F   
    -- 取得*小類*的資訊與數量設定   
    JOIN P_FoodEntKind_Mould PEK ON PEK.EnterpriseID = @enterpriseId AND PEK.MouldCode IN (SELECT MouldCode FROM @MouldCodesTable) AND PEK.FoodID = F.FoodId   
    LEFT JOIN P_Data_Language_D LANGKIND   
        ON LANGKIND.EnterpriseID = @enterpriseid   
        AND LANGKIND.SourceID = PEK.KindID   
        AND LANGKIND.TableName = 'FoodKind'
    LEFT JOIN  P_FoodKind PFK ON PFK.EnterpriseID = @enterpriseId AND PFK.ID = PEK.KindID
    ORDER BY F.FoodId, PEK.EntKindNo    
END
GO
