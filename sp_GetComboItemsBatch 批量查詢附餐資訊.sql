-- CREATE PROCEDURE [dbo].[sp_GetComboItemsBatch] 
-- AS 
-- DECLARE    @enterpriseId NVARCHAR(50) = 'XFlamorning' 
-- DECLARE    @shopId NVARCHAR(50) = '02A06' 
-- DECLARE    @foodIds NVARCHAR(MAX) = 'P0032453,P0032498,P0032500,P0032506,P0032512,P0032532,P0032554,P0132585,P0132601,P0132603,P0132605,P0132607,P0132609,P0132611,P0132626,P0132628,P0132630,P0132632,P0132634,P0132636,P0132638,P0132640,P0132644,P0132643,P0139859,P0232646,P0232648,P0232650,P0232653,P0232655,P0232657,P0232659,P0232661,P0232663,P0232665,P0232667,P0332669,P0332671,P0332673,P0332675,P0332677,P0332679,P0332681,P0332683,P0332685,P0332687,P0332692,P0332694,P0332696,P0332698,P0332700,P0332702,P0332704,P0332706,P0432708,P0432710,P0432712,P0432714,P0432716,P0432800,P0432802,P0532812,P0532816,P0532818,P0532820,P0632822,P0632824,P0632826,P0632828,P0632831,P0632833,P0732836,P0732838,P0732840,P0732907,P0832911,P0832919,P0832925,P0832935,P0832943,P0832948,P0932913,P0932915,P0932917,P1032921,P1032924,P1032927,P1232953,P1232956,P1232959,P1332952,P1332957,P1332961,P1332964,P1432966,P1432969,P1432971,P1432973,P1432978,P1433004,P1433007,P1433015,P1433022,P1433027,P2439815,P2439833,P2439839,P2439820,P2439827,P2439824,P2439810'
-- DECLARE    @orderType NVARCHAR(50) = 'scaneDesk' 
-- DECLARE    @langId NVARCHAR(50) = 'TW'
BEGIN 
    SET NOCOUNT ON; 
     
    -- 1. 首先創建必要的索引
    CREATE INDEX IX_P_FOODENT_EnterpriseID_MainFood ON P_FOODENT(EnterpriseID, MainFood);
    CREATE INDEX IX_P_FoodEntKind_EnterpriseID_FoodID ON P_FoodEntKind(EnterpriseID, FoodID);
    CREATE INDEX IX_P_FoodKind_EnterpriseID_ID ON P_FoodKind(EnterpriseID, ID);

    -- 2. 優化後的存儲過程
    -- CREATE PROCEDURE [dbo].[sp_GetComboItemsBatch] 
    --     @enterpriseId NVARCHAR(50),
    --     @shopId NVARCHAR(50),
    --     @foodIds NVARCHAR(MAX),
    --     @orderType NVARCHAR(50),
    --     @langId NVARCHAR(50)
    -- AS 
    DECLARE    @enterpriseId NVARCHAR(50) = 'XFlamorning' 
DECLARE    @shopId NVARCHAR(50) = '02A06' 
DECLARE    @foodIds NVARCHAR(MAX) = 'P0032453,P0032498,P0032500,P0032506,P0032512,P0032532,P0032554,P0132585,P0132601,P0132603,P0132605,P0132607,P0132609,P0132611,P0132626,P0132628,P0132630,P0132632,P0132634,P0132636,P0132638,P0132640,P0132644,P0132643,P0139859,P0232646,P0232648,P0232650,P0232653,P0232655,P0232657,P0232659,P0232661,P0232663,P0232665,P0232667,P0332669,P0332671,P0332673,P0332675,P0332677,P0332679,P0332681,P0332683,P0332685,P0332687,P0332692,P0332694,P0332696,P0332698,P0332700,P0332702,P0332704,P0332706,P0432708,P0432710,P0432712,P0432714,P0432716,P0432800,P0432802,P0532812,P0532816,P0532818,P0532820,P0632822,P0632824,P0632826,P0632828,P0632831,P0632833,P0732836,P0732838,P0732840,P0732907,P0832911,P0832919,P0832925,P0832935,P0832943,P0832948,P0932913,P0932915,P0932917,P1032921,P1032924,P1032927,P1232953,P1232956,P1232959,P1332952,P1332957,P1332961,P1332964,P1432966,P1432969,P1432971,P1432973,P1432978,P1433004,P1433007,P1433015,P1433022,P1433027,P2439815,P2439833,P2439839,P2439820,P2439827,P2439824,P2439810'
DECLARE    @orderType NVARCHAR(50) = 'scaneDesk' 
DECLARE    @langId NVARCHAR(50) = 'TW'
    BEGIN 
        SET NOCOUNT ON; 
        
        -- 創建臨時表存儲分割後的 FoodIds
        CREATE TABLE #FoodIdsTable (FoodId NVARCHAR(50));
        INSERT INTO #FoodIdsTable 
        SELECT value FROM STRING_SPLIT(@foodIds, ',');
        
        -- 創建臨時表存儲主要查詢結果
        CREATE TABLE #MainResults (
            FoodId NVARCHAR(50),
            ItemId NVARCHAR(50),
            ItemName NVARCHAR(200),
            MinSelectCount INT,
            MaxSelectCount INT,
            Sort INT
        );
        
        -- 使用 CTE 優化主要查詢
        WITH MainQuery AS (
            SELECT DISTINCT 
                F.FoodId,
                PDK.ID AS ItemId,
                ISNULL(JSON_VALUE(LANGKIND.Content, '$.' + @langId + '.Name'), PDK.Name) AS ItemName,
                PEK.MaxCount AS MaxSelectCount,
                PEK.EntKindNo AS Sort
            FROM #FoodIdsTable F 
            JOIN P_FOODENT PENT ON PENT.EnterpriseID = @enterpriseId AND PENT.MainFood = F.FoodId 
            JOIN P_FoodEntKind PEK ON PEK.EnterpriseID = @enterpriseId AND PENT.MainFood = PEK.FoodID 
            JOIN P_FoodKind PDK ON PDK.EnterpriseID = @enterpriseId AND PEK.KindID = PDK.ID 
            JOIN P_FOOD PD ON PD.EnterpriseID = @enterpriseId AND PENT.MainFood = PD.ID 
            JOIN P_FoodMould FP ON FP.EnterpriseID = @enterpriseId AND PD.ID = FP.ID 
            JOIN P_FoodMould_M fm ON fm.EnterpriseID = @enterpriseId AND FP.MouldCode = fm.MouldCode 
            JOIN P_FoodMould_Shop fshop ON fshop.EnterpriseID = @enterpriseId AND fm.MouldCode = fshop.MouldCode 
            JOIN P_FoodKind_Mould K1 ON K1.EnterpriseID = @enterpriseId AND K1.MouldCode = fm.MouldCode AND k1.id = fp.kind 
            JOIN p_foodkind2 K2 ON K2.EnterpriseID = @enterpriseId AND K2.ID = FP.kind2 AND k2.id = k1.FLevel 
            LEFT JOIN P_Data_Language_D LANGKIND ON LANGKIND.EnterpriseID = @enterpriseid AND LANGKIND.SourceID = PDK.ID AND LANGKIND.TableName = 'FoodKind' 
            WHERE fshop.shopid = @shopId 
                AND fm.status = 9 
                AND fm.MouldType = CASE @orderType 
                    WHEN 'takeout' THEN 2 
                    WHEN 'delivery' THEN 5 
                    WHEN 'scaneDesk' THEN 6 
                END
        )
        INSERT INTO #MainResults
        SELECT 
            FoodId,
            ItemId,
            ItemName,
            1 AS MinSelectCount,
            MaxSelectCount,
            Sort
        FROM MainQuery;

        -- 創建臨時表存儲 FoodItems 數據
        CREATE TABLE #FoodItems (
            FoodId NVARCHAR(50),
            ItemId NVARCHAR(50),
            FoodItems NVARCHAR(MAX)
        );

        -- 使用 CTE 優化 FoodItems 查詢
        WITH FoodItemsCTE AS (
            SELECT 
                ENT.MainFood AS FoodId,
                M.Kind AS ItemId,
                (
                    SELECT 
                        ENT.EntFood AS FoodId,
                        ISNULL(SUF.Dir, '') AS ImagePath,
                        ISNULL(JSON_VALUE(LANGFOOD.Content, '$.' + @langId + '.Name'), M.Name) AS FoodName,
                        PF.Introduce AS Description,
                        ENT.Price AS Price,
                        ENT.EntNo AS Sort,
                        CAST(CASE WHEN M.Stop = 0 THEN 1 ELSE 0 END AS BIT) AS IsSoldOut
                    FROM P_FOODENT ENT 
                    JOIN P_FoodMould M ON ENT.EnterpriseID = M.EnterpriseID AND ENT.EntFood = M.ID 
                    JOIN P_Food PF ON ENT.EnterpriseID = PF.EnterpriseID AND ENT.EntFood = PF.ID 
                    LEFT JOIN S_UploadFile SUF ON ENT.EnterpriseID = SUF.EnterpriseID AND SUF.ItemID = ENT.EntFood AND SUF.vType = 'food2' 
                    LEFT JOIN P_Data_Language_D LANGFOOD ON LANGFOOD.EnterpriseID = @enterpriseid AND LANGFOOD.SourceID = M.ID AND LANGFOOD.TableName = 'Food' 
                    WHERE ENT.EnterpriseID = @enterpriseId 
                        AND ENT.MainFood = ENT.MainFood 
                        AND M.Kind = M.Kind 
                        AND ENT.EntFood IS NOT NULL 
                    ORDER BY ENT.EntNo 
                    FOR JSON PATH
                ) AS FoodItems
            FROM P_FOODENT ENT 
            JOIN P_FoodMould M ON ENT.EnterpriseID = M.EnterpriseID AND ENT.EntFood = M.ID 
            WHERE ENT.EnterpriseID = @enterpriseId 
            GROUP BY ENT.MainFood, M.Kind
        )
        INSERT INTO #FoodItems
        SELECT FoodId, ItemId, FoodItems
        FROM FoodItemsCTE;

        -- 最終結果
        SELECT 
            m.FoodId,
            m.ItemId,
            m.ItemName,
            f.FoodItems,
            m.MinSelectCount,
            m.MaxSelectCount,
            m.Sort
        FROM #MainResults m
        LEFT JOIN #FoodItems f ON m.FoodId = f.FoodId AND m.ItemId = f.ItemId
        ORDER BY m.FoodId, m.Sort;

        -- 清理臨時表
        DROP TABLE #FoodIdsTable;
        DROP TABLE #MainResults;
        DROP TABLE #FoodItems;
    END
END