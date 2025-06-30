CREATE OR ALTER PROCEDURE [dbo].[sp_GetFoodOptionsBatch] 
    @enterpriseId NVARCHAR(50), 
    @shopId NVARCHAR(50), 
    @foodIds NVARCHAR(MAX), 
    @orderType NVARCHAR(50), 
    @langId NVARCHAR(50) 
AS 

-- DECLARE
--     @enterpriseId NVARCHAR(50) = '90367984', 
--     @shopId NVARCHAR(50) = 'A01', 
--     @foodIds NVARCHAR(MAX) = 'Mp734905', 
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
                CAST(0 AS BIT) AS IsSoldOut 
            FROM P_FoodAdd_Mould FA2
            JOIN P_FoodMould_Shop FMS2 ON FMS2.EnterpriseID = @enterpriseId AND FMS2.ShopID = @shopId
            JOIN P_FoodMould_M FMM2 ON FMM2.EnterPriseID = @enterpriseId      
                AND FMM2.MouldCode = FMS2.MouldCode      
                AND FMM2.[Status] = 9     
                AND FMM2.MouldType = CASE @orderType     
                    WHEN 'takeout' THEN 2     
                    WHEN 'delivery' THEN 5      
                    WHEN 'scaneDesk' THEN 6
                END
            LEFT JOIN P_Data_Language_D LANGADD 
                ON LANGADD.EnterpriseID = @enterpriseid 
                AND LANGADD.SourceID = FA2.ID 
                AND LANGADD.TableName = 'FoodAdd' 
            WHERE FA2.AddKindID = FAK.ID 
            AND FA2.EnterpriseID = @enterpriseId 
            AND FA2.Owner = F.FoodId 
            AND FA2.MouldCode = FMS2.MouldCode
            ORDER BY FA2.SN 
            FOR JSON PATH 
        ) AS Items, 
        CASE FAK.needed 
            WHEN 0 THEN 0 
            WHEN 1 THEN 1 
        END AS MinSelectCount, 
        FAK.MaxCount AS MaxSelectCount 
    FROM @FoodIdsTable F 
    JOIN P_FoodAdd_Mould FAM ON FAM.EnterpriseID = @enterpriseId AND FAM.Owner = F.FoodId 
    JOIN P_FoodMould_Shop FMS ON FMS.EnterpriseID = @enterpriseId AND FMS.ShopID = @shopId
    JOIN P_FoodMould_M FMM ON FMM.EnterPriseID = @enterpriseId      
        AND FMM.MouldCode = FMS.MouldCode      
        AND FMM.[Status] = 9     
        AND FMM.MouldType = CASE @orderType     
            WHEN 'takeout' THEN 2     
            WHEN 'delivery' THEN 5      
            WHEN 'scaneDesk' THEN 6
        END
    JOIN P_FoodAddKind FAK ON FAK.ID = FAM.AddKindID AND FAM.MouldCode = FMS.MouldCode
    LEFT JOIN P_Data_Language_D LANGKIND 
        ON LANGKIND.EnterpriseID = @enterpriseid 
        AND LANGKIND.SourceID = FAK.ID 
        AND LANGKIND.TableName = 'FoodAddKind' 
    GROUP BY F.FoodId, FAK.ID, FAK.Name, FAK.MaxCount, FAK.needed, LANGKIND.Content 
END