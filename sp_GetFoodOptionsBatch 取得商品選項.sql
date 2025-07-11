CREATE OR ALTER PROCEDURE [dbo].[sp_GetFoodOptionsBatch]  
    @enterpriseId NVARCHAR(50),  
    @shopId NVARCHAR(50),  
    @foodIds NVARCHAR(MAX),  
    @orderType NVARCHAR(50),  
    @langId NVARCHAR(50)  
AS  
 
-- DECLARE 
--     @enterpriseId NVARCHAR(50) = 'xurf',  
--     @shopId NVARCHAR(50) = 'A002',
--     @foodIds NVARCHAR(MAX) = 'AH00146999',
--     @orderType NVARCHAR(50) = 'scaneDesk',
--     @langId NVARCHAR(50) = 'TW'  
 
 
BEGIN  
    SET NOCOUNT ON;  
      
    -- 將逗號分隔的 foodIds 轉換為表格  
    DECLARE @FoodIdsTable TABLE (FoodId NVARCHAR(50))  
    INSERT INTO @FoodIdsTable  
    SELECT value FROM STRING_SPLIT(@foodIds, ',')  
  
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
                ISNULL(PFMJ.Stop,0) AS IsSoldOut  
            FROM P_FoodAdd_Mould FA2 
            LEFT JOIN P_Data_Language_D LANGADD  
                ON LANGADD.EnterpriseID = @enterpriseid  
                AND LANGADD.SourceID = FA2.ID  
                AND LANGADD.TableName = 'FoodAdd'
            LEFT JOIN P_FoodTasteAddMouldJoin PFMJ on PFMJ.EnterpriseID = @enterpriseId and PFMJ.TasteAddName = FA2.Name and PFMJ.ShopID = @shopId
            WHERE FA2.AddKindID = FAK.ID  
            AND FA2.EnterpriseID = @enterpriseId  
            AND FA2.Owner = F.FoodId  
            AND FA2.MouldCode = FMM.MouldCode
            ORDER BY FA2.SN  
            FOR JSON PATH  
        ) AS Items,  
        FAK.needed AS MinSelectCount,
        FAK.MaxCount AS MaxSelectCount
    FROM @FoodIdsTable F
    -- 透過 P_FoodMould_Shop、P_FoodMould_M 找出目標菜單的 MouldCode
    JOIN P_FoodMould_Shop FMS ON FMS.EnterpriseID = @enterpriseId AND FMS.ShopID = @shopId
    JOIN P_FoodMould_M FMM ON FMM.EnterPriseID = @enterpriseId     
        AND FMM.MouldCode = FMS.MouldCode     
        AND FMM.[Status] = 9      
        AND FMM.MouldType = CASE @orderType      
            WHEN 'takeout' THEN 2      
            WHEN 'delivery' THEN 5       
            WHEN 'scaneDesk' THEN 6 
        END 
    JOIN P_FoodAdd_Mould FAM ON FAM.EnterpriseID = @enterpriseId AND FAM.Owner = F.FoodId AND FAM.MouldCode = FMM.MouldCode
    JOIN P_FoodAddKind FAK ON FAK.ID = FAM.AddKindID
    -- 依據語系找出對應的顯示文字
    LEFT JOIN P_Data_Language_D LANGKIND  
        ON LANGKIND.EnterpriseID = @enterpriseid  
        AND LANGKIND.SourceID = FAK.ID  
        AND LANGKIND.TableName = 'FoodAddKind'  
    GROUP BY F.FoodId, FAK.ID, FAK.Name, FAK.MaxCount, FAK.needed, LANGKIND.Content, FMM.MouldCode
END