SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ALTER   PROCEDURE [dbo].[sp_GetFoodList2]         
--     @enterpriseId NVARCHAR(50),    -- 企業ID         
--     @shopId NVARCHAR(50),          -- 店鋪ID          
--     @langId NVARCHAR(50) = 'TW',   -- 語系ID         
--     @foodId NVARCHAR(50) = NULL,   -- 食品ID     
--     @mouldCodes NVARCHAR(MAX),     -- 菜單代碼清單（逗號分隔）
--     @showHidenKind BIT = 0          -- 是否顯示隱藏分類（預設為false）
-- AS     

DECLARE
@enterpriseId NVARCHAR(50) = 'XF93277699',    -- 企業ID         
    @shopId NVARCHAR(50) = 'A01',          -- 店鋪ID          
    @langId NVARCHAR(50) = 'TW',   -- 語系ID         
    @foodId NVARCHAR(50) = NULL,   -- 食品ID     
    @mouldCodes NVARCHAR(MAX) = 'OnlineTogo_A01001',     -- 菜單代碼清單（逗號分隔）
    @showHidenKind BIT = 0          -- 是否顯示隱藏分類（預設為false）

BEGIN         
    SET NOCOUNT ON;         
         
    BEGIN TRY         
        
        -- 將逗號分隔的 mouldCodes 轉換為表格    
        DECLARE @MouldCodesTable TABLE (MouldCode NVARCHAR(50) COLLATE Chinese_PRC_CI_AS)    
        INSERT INTO @MouldCodesTable    
        SELECT value FROM STRING_SPLIT(@mouldCodes, ',')    

        -- 預先彙總「套餐升級清單」，避免在主查詢中對每筆商品做相關子查詢
        IF OBJECT_ID('tempdb..#UpgradeList') IS NOT NULL
            DROP TABLE #UpgradeList;
        CREATE TABLE #UpgradeList (
            MouldCode NVARCHAR(50) COLLATE Chinese_PRC_CI_AS,
            EntFood NVARCHAR(50) COLLATE Chinese_PRC_CI_AS,
            UpgradeList NVARCHAR(MAX)
        );

        ;WITH ComboItems AS (
            SELECT DISTINCT
                PFEM.MouldCode,
                PFEM.EntFood,
                PFM.ID AS ComboFoodId,
                COALESCE(JSON_VALUE(LANGPFM.Content, '$.' + @langId + '.Name'), PFM.Name) AS ComboFoodName,
                PFM.price AS ComboPrice
            FROM P_FoodEnt_Mould PFEM
            JOIN P_FoodMould PFM
                ON PFM.EnterpriseID = @enterpriseId
                AND PFM.MouldCode COLLATE Chinese_PRC_CI_AS = PFEM.MouldCode COLLATE Chinese_PRC_CI_AS
                AND PFM.YSFlag = 1          -- 只找套餐
                AND PFM.ID = PFEM.MainFood
                AND PFM.Hide = 0  
            LEFT JOIN P_Data_Language_D LANGPFM
                ON LANGPFM.EnterpriseID = @enterpriseId
                AND LANGPFM.SourceID = PFM.ID
                AND LANGPFM.TableName = 'Food'    
            WHERE PFEM.EnterpriseID = @enterpriseId    
                AND PFEM.MouldCode COLLATE Chinese_PRC_CI_AS IN (SELECT MouldCode FROM @MouldCodesTable)
        )
        INSERT INTO #UpgradeList (MouldCode, EntFood, UpgradeList)
        SELECT
            MouldCode,
            EntFood,
            '[' + STRING_AGG(
                    CONCAT(
                        '{"FoodId":"', CAST(ComboFoodId AS NVARCHAR(50)),
                        '","FoodName":"', ISNULL(ComboFoodName, ''),
                        '","Price":', CAST(ComboPrice AS NVARCHAR(20)),
                        '}'
                    ),
                    ','
                ) + ']'
        FROM ComboItems
        GROUP BY MouldCode, EntFood;

    -- [優化] 分流邏輯
    IF (@langId = 'TW' OR @langId IS NULL)
    BEGIN
        -- [路徑 A] 預設語系 (TW)：移除多語系 Join 與 JSON 解析
        SELECT         
            FM.Kind AS FoodCategoryId,  -- 食品分類ID         
            FK.Name AS FoodCategoryName,  -- [優化] 直接取 Name
            FK.Sn AS FoodCategorySort,  -- 食品分類排序         
            FM.ID AS FoodId,            -- 食品ID         
            FM.Name AS FoodName,          -- [優化] 直接取 Name
            FM.Name AS OriginFoodName, -- 食品原始名稱
            FM.PriceExpr AS MultiPriceType, -- 多價位標記("1"為頭、值為 FoodId 代表是多價位子項)
            FM.CurPrice AS DefaultMultiPrice, -- 多價位子項是否為預設
            FM.stop AS [Stop], -- 販售狀態
            (                   
                SELECT TOP 1 Dir          
                FROM S_UploadFile UF          
                WHERE UF.enterpriseid = @enterpriseId AND UF.itemid = FM.ID          
            ) AS ImagePath,  -- 取食品圖片路徑（僅取一筆）    
            F.Introduce AS Description, -- 食品描述         
            CASE WHEN FM.YSFlag = 1 THEN 1 ELSE 0 END AS IsCombo,  -- 是否為套餐（YSFlag=1為套餐，0為單品）         
            FM.price AS Price,  -- 價格

            -- 套餐升級清單（找出包含當前商品的套餐）    
            CASE     
                WHEN FM.YSFlag = 0 THEN ISNULL(UL.UpgradeList, '[]')  -- 使用預先彙總結果，避免逐列子查詢
                ELSE '[]'    
            END AS UpgradeList,         
            FM.Sn AS Sort,               -- 排序         
                
            -- 促銷活動清單（若有多個促銷，組成JSON陣列字串）         
            CASE           
                WHEN EXISTS (          
                    SELECT 1          
                    FROM p_agiokind gkind_inner          
                    JOIN P_AgioItems aitem           
                        ON gkind_inner.EnterpriseID = @enterpriseId          
                        AND gkind_inner.id = aitem.AgioKind          
                    JOIN P_AgioItems_Shop ashop           
                        ON aitem.EnterpriseID = @enterpriseId          
                        AND aitem.gid = ashop.MGID          
                    JOIN P_Agio_FoodKind_Mould amould           
                        ON amould.EnterpriseID = @enterpriseId          
                        AND amould.MouldCode = aitem.gid          
                JOIN P_Agio_FoodMould afmould           
                        ON afmould.EnterpriseID = @enterpriseId          
                        AND afmould.MouldCode = amould.MouldCode          
                    WHERE           
                        gkind_inner.EnterpriseID = @enterpriseId          
                        AND ashop.shopid = @shopId      
                        AND aitem.DiscountKind IN ('ASinglePercent', 'AsingleCost')          
                        AND afmould.id = FM.ID         
            )          
                THEN CONCAT('[',           
                    STUFF((          
                        SELECT DISTINCT          
                            ',"' + aitem.Name + '"'          
                        FROM           
                            p_agiokind gkind_inner          
                            JOIN P_AgioItems aitem           
                                ON gkind_inner.EnterpriseID = aitem.EnterpriseID          
                                AND gkind_inner.id = aitem.AgioKind          
                            JOIN P_AgioItems_Shop ashop           
                                ON aitem.EnterpriseID = ashop.EnterpriseID          
                                AND aitem.gid = ashop.MGID          
                            JOIN P_Agio_FoodKind_Mould amould           
                                ON amould.EnterpriseID = ashop.EnterpriseID          
                                AND amould.MouldCode = aitem.gid          
                            JOIN P_Agio_FoodMould afmould           
                                ON afmould.EnterpriseID = ashop.EnterpriseID          
                                AND afmould.MouldCode = amould.MouldCode          
                        WHERE           
                            gkind_inner.EnterpriseID = @enterpriseId          
                            AND ashop.shopid = @shopId          
                            AND aitem.DiscountKind IN ('ASinglePercent', 'AsingleCost')          
                            AND afmould.id = FM.id          
                        FOR XML PATH('')          
                    ), 1, 1, ''),           
                ']')          
                ELSE '[]'          
            END AS PromotionList,  -- 促銷活動名稱清單（JSON 字串）         
                
            ISNULL(          
            (          
                -- 取第一個促銷活動類別名稱作為Badge顯示(促銷類別在後台沒有在用了，全部都在同一個類別下)         
                SELECT TOP 1 gkind.Name          
                FROM           
                    p_agiokind gkind          
                    JOIN P_AgioItems aitem           
                        ON gkind.EnterpriseID = @enterpriseId         
                        AND gkind.id = aitem.AgioKind          
                    JOIN P_AgioItems_Shop ashop           
                        ON aitem.EnterpriseID = @enterpriseId          
                        AND aitem.gid = ashop.MGID          
                    JOIN P_Agio_FoodKind_Mould amould           
                        ON amould.EnterpriseID = @enterpriseId          
                        AND amould.MouldCode = aitem.gid          
                    JOIN P_Agio_FoodMould afmould           
                        ON afmould.EnterpriseID = @enterpriseId          
                        AND afmould.MouldCode = amould.MouldCode          
                WHERE           
                    gkind.EnterpriseID = @enterpriseId          
                    AND ashop.shopid = @shopId          
                    AND aitem.DiscountKind IN ('ASinglePercent', 'AsingleCost')          
                    AND afmould.id = FM.id          
            ),''          
            ) AS PromotionBadge,              -- 優惠 Badge             
            ISNULL(PFMJ.Stop,0) AS IsSoldOut  -- POS 停售
        FROM P_FoodMould FM         
            -- 關聯食品小分類 ( 根據 @showHidenKind 參數決定是否過濾隱藏小分類 )     
            JOIN P_FoodKind_Mould FK ON FK.EnterpriseID = @enterpriseId AND FK.ID = FM.Kind AND FK.MouldCode = FM.MouldCode AND (@showHidenKind = 1 OR FK.Hide = 0 OR @foodId is not null)   -- @showHidenKind=1 時不過濾隱藏分類   
            -- 關聯食品資料 
            JOIN P_Food F ON F.EnterpriseID = @enterpriseId AND F.Kind = FM.Kind AND F.ID = FM.ID 
            -- [優化] 移除多語系 Join
            -- LEFT JOIN P_Data_Language_D LANGKIND ON LANGKIND.EnterpriseID = @enterpriseid AND LANGKIND.SourceID = FM.Kind AND LANGKIND.TableName = 'FoodKind'         
            -- LEFT JOIN P_Data_Language_D LANGFOOD ON LANGFOOD.EnterpriseID = @enterpriseid AND LANGFOOD.SourceID = FM.ID AND LANGFOOD.TableName = 'Food'     
            -- 商品停售 
            LEFT JOIN P_FoodMouldJoin PFMJ on FM.EnterpriseID = PFMJ.EnterpriseID and FM.MouldCode = PFMJ.MouldCode and FM.ID = PFMJ.FoodID and PFMJ.ShopID = @shopId 
            LEFT JOIN #UpgradeList UL ON UL.MouldCode = FM.MouldCode COLLATE Chinese_PRC_CI_AS AND UL.EntFood = FM.ID COLLATE Chinese_PRC_CI_AS
        WHERE FM.EnterPriseID = @enterpriseId 
            AND (@foodId IS NULL OR FM.ID = @foodId)
            AND (FM.Hide IS NULL OR FM.Hide = 0) -- 非隱藏的餐點
            AND FM.MouldCode COLLATE Chinese_PRC_CI_AS IN (SELECT MouldCode FROM @MouldCodesTable)
        ORDER BY FoodCategoryId, Sort
        OPTION(RECOMPILE);
    END
    ELSE
    BEGIN
        -- [路徑 B] 非預設語系：維持原有邏輯
        SELECT         
            FM.Kind AS FoodCategoryId,  -- 食品分類ID         
            ISNULL(JSON_VALUE(LANGKIND.Content, '$.' + @langId + '.Name'), FK.Name) AS FoodCategoryName,  -- 食品分類名稱（多語系）
            FK.Sn AS FoodCategorySort,  -- 食品分類排序         
            FM.ID AS FoodId,            -- 食品ID         
            ISNULL(JSON_VALUE(LANGFOOD.Content, '$.' + @langId + '.Name'), FM.Name) AS FoodName,          -- 食品名稱（多語系）          
            FM.Name AS OriginFoodName, -- 食品原始名稱
            FM.stop AS [Stop], -- 販售狀態
            (                   
                SELECT TOP 1 Dir          
                FROM S_UploadFile UF          
                WHERE UF.enterpriseid = @enterpriseId AND UF.itemid = FM.ID          
            ) AS ImagePath,  -- 取食品圖片路徑（僅取一筆）    
            F.Introduce AS Description, -- 食品描述         
            CASE WHEN FM.YSFlag = 1 THEN 1 ELSE 0 END AS IsCombo,  -- 是否為套餐（YSFlag=1為套餐，0為單品）         
            FM.price AS Price,  -- 價格

            -- 套餐升級清單（找出包含當前商品的套餐）    
            CASE     
                WHEN FM.YSFlag = 0 THEN ISNULL(UL.UpgradeList, '[]')  -- 使用預先彙總結果，避免逐列子查詢
                ELSE '[]'    
            END AS UpgradeList,         
            FM.Sn AS Sort,               -- 排序         
                
            -- 促銷活動清單（若有多個促銷，組成JSON陣列字串）         
            CASE           
                WHEN EXISTS (          
                    SELECT 1          
                    FROM p_agiokind gkind_inner          
                    JOIN P_AgioItems aitem           
                        ON gkind_inner.EnterpriseID = @enterpriseId          
                        AND gkind_inner.id = aitem.AgioKind          
                    JOIN P_AgioItems_Shop ashop           
                        ON aitem.EnterpriseID = @enterpriseId          
                        AND aitem.gid = ashop.MGID          
                    JOIN P_Agio_FoodKind_Mould amould           
                        ON amould.EnterpriseID = @enterpriseId          
                        AND amould.MouldCode = aitem.gid          
                JOIN P_Agio_FoodMould afmould           
                        ON afmould.EnterpriseID = @enterpriseId          
                        AND afmould.MouldCode = amould.MouldCode          
                    WHERE           
                        gkind_inner.EnterpriseID = @enterpriseId          
                        AND ashop.shopid = @shopId      
                        AND aitem.DiscountKind IN ('ASinglePercent', 'AsingleCost')          
                        AND afmould.id = FM.ID         
            )          
                THEN CONCAT('[',           
                    STUFF((          
                        SELECT DISTINCT          
                            ',"' + aitem.Name + '"'          
                        FROM           
                            p_agiokind gkind_inner          
                            JOIN P_AgioItems aitem           
                                ON gkind_inner.EnterpriseID = aitem.EnterpriseID          
                                AND gkind_inner.id = aitem.AgioKind          
                            JOIN P_AgioItems_Shop ashop           
                                ON aitem.EnterpriseID = ashop.EnterpriseID          
                                AND aitem.gid = ashop.MGID          
                            JOIN P_Agio_FoodKind_Mould amould           
                                ON amould.EnterpriseID = ashop.EnterpriseID          
                                AND amould.MouldCode = aitem.gid          
                            JOIN P_Agio_FoodMould afmould           
                                ON afmould.EnterpriseID = ashop.EnterpriseID          
                                AND afmould.MouldCode = amould.MouldCode          
                        WHERE           
                            gkind_inner.EnterpriseID = @enterpriseId          
                            AND ashop.shopid = @shopId          
                            AND aitem.DiscountKind IN ('ASinglePercent', 'AsingleCost')          
                            AND afmould.id = FM.id          
                        FOR XML PATH('')          
                    ), 1, 1, ''),           
                ']')          
                ELSE '[]'          
            END AS PromotionList,  -- 促銷活動名稱清單（JSON 字串）         
                
            ISNULL(          
            (          
                -- 取第一個促銷活動類別名稱作為Badge顯示(促銷類別在後台沒有在用了，全部都在同一個類別下)         
                SELECT TOP 1 gkind.Name          
                FROM           
                    p_agiokind gkind          
                    JOIN P_AgioItems aitem           
                        ON gkind.EnterpriseID = @enterpriseId         
                        AND gkind.id = aitem.AgioKind          
                    JOIN P_AgioItems_Shop ashop           
                        ON aitem.EnterpriseID = @enterpriseId          
                        AND aitem.gid = ashop.MGID          
                    JOIN P_Agio_FoodKind_Mould amould           
                        ON amould.EnterpriseID = @enterpriseId          
                        AND amould.MouldCode = aitem.gid          
                    JOIN P_Agio_FoodMould afmould           
                        ON afmould.EnterpriseID = @enterpriseId          
                        AND afmould.MouldCode = amould.MouldCode          
                WHERE           
                    gkind.EnterpriseID = @enterpriseId          
                    AND ashop.shopid = @shopId          
                    AND aitem.DiscountKind IN ('ASinglePercent', 'AsingleCost')          
                    AND afmould.id = FM.id          
            ),''          
            ) AS PromotionBadge,              -- 優惠 Badge             
            ISNULL(PFMJ.Stop,0) AS IsSoldOut  -- POS 停售
        FROM P_FoodMould FM         
            -- 關聯食品小分類 ( 根據 @showHidenKind 參數決定是否過濾隱藏小分類 )     
            JOIN P_FoodKind_Mould FK ON FK.EnterpriseID = @enterpriseId AND FK.ID = FM.Kind AND FK.MouldCode = FM.MouldCode AND (@showHidenKind = 1 OR FK.Hide = 0 OR @foodId is not null)   -- @showHidenKind=1 時不過濾隱藏分類   
            -- 關聯食品資料 
            JOIN P_Food F ON F.EnterpriseID = @enterpriseId AND F.Kind = FM.Kind AND F.ID = FM.ID 
            -- 多語系：食品小分類 
            LEFT JOIN P_Data_Language_D LANGKIND ON LANGKIND.EnterpriseID = @enterpriseid AND LANGKIND.SourceID = FM.Kind AND LANGKIND.TableName = 'FoodKind'         
            -- 多語系：食品名稱 
            LEFT JOIN P_Data_Language_D LANGFOOD ON LANGFOOD.EnterpriseID = @enterpriseid AND LANGFOOD.SourceID = FM.ID AND LANGFOOD.TableName = 'Food'     
            -- 商品停售 
            LEFT JOIN P_FoodMouldJoin PFMJ on FM.EnterpriseID = PFMJ.EnterpriseID and FM.MouldCode = PFMJ.MouldCode and FM.ID = PFMJ.FoodID and PFMJ.ShopID = @shopId 
            LEFT JOIN #UpgradeList UL ON UL.MouldCode = FM.MouldCode COLLATE Chinese_PRC_CI_AS AND UL.EntFood = FM.ID COLLATE Chinese_PRC_CI_AS
        WHERE FM.EnterPriseID = @enterpriseId 
            AND (@foodId IS NULL OR FM.ID = @foodId)
            AND (FM.Hide IS NULL OR FM.Hide = 0) -- 非隱藏的餐點
            AND FM.MouldCode COLLATE Chinese_PRC_CI_AS IN (SELECT MouldCode FROM @MouldCodesTable)
        ORDER BY FoodCategoryId, Sort
        OPTION(RECOMPILE);
    END
    END TRY          
    BEGIN CATCH          
        -- 錯誤處理區，將錯誤訊息回傳給呼叫端         
        DECLARE @ErrorMessage NVARCHAR(4000);          
        DECLARE @ErrorSeverity INT;          
        DECLARE @ErrorState INT;          
          
        SELECT           
            @ErrorMessage = ERROR_MESSAGE(),          
            @ErrorSeverity = ERROR_SEVERITY(),          
            @ErrorState = ERROR_STATE();          
          
        -- 返回錯誤信息          
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);          
    END CATCH;          
END
GO
