CREATE PROCEDURE [dbo].[sp_GetFoodList2] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @shopId NVARCHAR(50), -- 門市Id 
    @categoryId NVARCHAR(50), -- 類別Id ,null就是給全部   (需要確定這個參數需要??) 
    @orderType NVARCHAR(50), -- 訂單類型 
    @langId NVARCHAR(50) = NULL -- 語系Id 
AS 
BEGIN 
    SET NOCOUNT ON; 
     
----  SELECT  
----  要核對是否為套餐這個是對到誰? 
----  'JUD01' AS FoodCategoryId,                   -- 餐點類別Id 
----  '1' AS FoodId,                               -- 餐點Id 
----  'https://s3-alphasig.figma.com/img/b80a/072b/2e4e2130fa59c0c6c47d72d18777ca27?Expires=1743984000&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=KEjVyPG8Xv0tn1i2zyoQxlYRphExN7SRkJu6-Bjwx~q2Jbn9FGoWFYoep91RVCQNlrNGCwBV6-rLs35ve4CHC0uMnJkdrT2ZVuDKxozBS0raUNS82YEX0pkj2WszZOvy~N1f5eOnJNgQw6W0Ypi0kJ8h0MlpqnyyLKPwzKeNPSFuqx9VhOxI~myACWEOF2tCmhAD30wl6DzkX~fD2y0fnmkeQWIPi71KAnLtZj9pgBHHRhWNxT26ceEVZ5xoKNKtqADzm85Zw9ZMjiBaH3eUX-NEZb67Vj9fVZJgaIO8TF2kaeM-fK56F0OkjOyBXZnARWJX6WiNHhyISJeKmJ4GaA__' AS ImagePath, -- 餐點照片路徑 
----  '個人套餐(外帶限定)' AS FoodName,             -- 餐點名稱 
----  '可任選以下主餐：松露野菇燉飯/紐奧良什錦飯/西班牙海鮮燉飯/義大利海鮮麵/番茄海鮮義大利麵/西西里鯷鮮烏魚子意麵/奶油雙菇雞肉麵/辣味義式蔬菜麵' AS Description, -- 餐點描述 
----  CAST(1 AS Bit) AS IsCombo,                   -- 是否為套餐 
----- 380 AS Price,                                -- 單價 
----  0 AS Sort,                                   -- 排序 
----  '["買一送一", "第二件半價"]' AS PromotionList, -- 優惠活動 
----  '滿量優惠' AS PromotionBadge,                 -- 優惠Badge 
----  CAST(0 AS Bit) AS IsSoldOut                  -- 是否停售

    BEGIN TRY 
        -- 套餐 
        SELECT DISTINCT 
            K1.ID AS FoodCategoryId,          -- 餐點類別Id 
        --  K1.name AS FoodCategoryName,      -- 餐點類別名稱 
        --  ISNULL(JSON_VALUE(LANGKIND.Content, '$.TW.Name'), K1.name) AS FoodCategoryNameMultiLang, -- 多語系類別名稱(固定TW) 
            FP.ID AS FoodId,                  -- 餐點Id 
            ( 
                SELECT TOP 1 Dir 
                FROM S_UploadFile SUF 
                WHERE SUF.enterpriseid = PDE.EnterpriseID AND SUF.itemid = PDE.ID 
            ) AS ImagePath,                   -- 餐點照片路徑 
            FP.name AS FoodName,              -- 餐點名稱 
        --  ISNULL(JSON_VALUE(LANGFOOD.Content, '$.TW.Name'), FP.name) AS FoodNameMultiLang, -- 多語系餐點名稱(固定TW) 
            PDE.introduce AS Description,     -- 餐點描述 
            CAST(1 AS Bit) AS IsCombo,        -- 是否為套餐 
            FP.price AS Price,                -- 單價 
            K1.Sn AS Sort,                    -- 排序 
            -- 使用CASE避免空陣列格式問題 
            CASE  
                WHEN EXISTS ( 
                    SELECT 1 
                    FROM p_agiokind gkind_inner 
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
                        AND afmould.id = FP.id 
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
                            AND afmould.id = FP.id 
                        FOR XML PATH('') 
                    ), 1, 1, ''),  
                ']') 
                ELSE '[]' 
            END AS PromotionList,           -- 優惠活動列表 
            ISNULL( 
            ( 
                SELECT TOP 1 gkind.Name 
                FROM  
                    p_agiokind gkind 
                    JOIN P_AgioItems aitem  
                        ON gkind.EnterpriseID = aitem.EnterpriseID 
                        AND gkind.id = aitem.AgioKind 
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
                    gkind.EnterpriseID = @enterpriseId 
                    AND ashop.shopid = @shopId 
                    AND aitem.DiscountKind IN ('ASinglePercent', 'AsingleCost') 
                    AND afmould.id = FP.id 
            ),'' 
            ) AS PromotionBadge,              -- 優惠Badge 
            CAST(CASE WHEN FP.stop = 1 THEN 1 ELSE 0 END AS Bit) AS IsSoldOut  -- 是否停售 
        FROM  
            P_FoodMould_Shop fshop 
            JOIN P_FoodMould_M fm  
                ON fshop.enterpriseid = fm.enterpriseid 
                AND fshop.mouldcode = fm.MouldCode 
                AND fm.status = 9 
            JOIN P_FOOD PD  
                ON PD.EnterpriseID = fshop.enterpriseid 
                AND PD.YSFlag = 1 
            JOIN P_foodMould FP  
                ON fm.enterpriseid = FP.EnterpriseID 
                AND fm.mouldcode = FP.MouldCode 
                AND FP.ID = PD.ID 
            JOIN P_FoodKind_Mould K1  
                ON K1.EnterpriseID = fshop.EnterPriseID 
                AND K1.MouldCode = fm.MouldCode 
                AND k1.id = fp.kind 
            JOIN p_foodkind2 K2  
                ON K2.EnterpriseID = K1.EnterpriseID 
                AND K2.ID = FP.kind2 
                AND k2.id = k1.FLevel 
            JOIN P_FOOD PDE  
                ON PD.EnterpriseID = PDE.EnterpriseID 
            JOIN P_FOODENT PENT  
                ON K1.EnterpriseID = PENT.EnterpriseID 
                AND PD.ID = PENT.MainFood 
                AND PENT.EntFood = PDE.ID 
            JOIN P_FoodEntKind PDEK  
                ON PDEK.EnterpriseID = fm.EnterpriseID 
                AND PDEK.FoodID = FP.ID 
            JOIN P_FoodKind PDK  
                ON PDEK.EnterpriseID = PDK.EnterpriseID 
                AND PDK.id = PDE.Kind 
                AND PDEK.KindID = PDK.ID 
            LEFT JOIN P_Data_Language_D LANGKIND  
                ON LANGKIND.EnterpriseID = @enterpriseId  
                AND LANGKIND.SourceID = K1.ID  
                AND LANGKIND.TableName = 'FoodKind' 
            LEFT JOIN P_Data_Language_D LANGFOOD  
                ON LANGFOOD.EnterpriseID = @enterpriseId  
                AND LANGFOOD.SourceID = FP.ID 
                AND LANGFOOD.TableName = 'Food' 
            -- 關聯訂單類型對應的表 
            LEFT JOIN P_FoodMould_M FMO 
                ON FMO.EnterpriseID = FP.EnterpriseID 
                AND FMO.MouldType in (2,5,6) 
                and fmo.MouldCode=fshop.MouldCode 
        WHERE  
            fshop.enterpriseid = @enterpriseId 
            AND fshop.shopid = @shopId 
            AND (@categoryId IS NULL OR K1.ID = @categoryId) 
            AND (@orderType IS NULL  
                 OR EXISTS ( 
                     SELECT 1  
                     FROM P_FoodMould_M FMO 
                     WHERE FMO.EnterpriseID = FP.EnterpriseID 
                           --AND FMO.FoodID = FP.ID 
                           AND FMO.MouldType in (2,5,6) 
                           AND fmo.MouldCode=fshop.MouldCode 
                 ) 
            ) 
 
        UNION 
 
        -- 單點 
        SELECT DISTINCT 
            K1.ID AS FoodCategoryId,          -- 餐點類別Id 
        --  K1.name AS FoodCategoryName,      -- 餐點類別名稱 
        --  ISNULL(JSON_VALUE(LANGKIND.Content, '$.TW.Name'), K1.name) AS FoodCategoryNameMultiLang, -- 多語系類別名稱(固定TW) 
            FP.ID AS FoodId,                  -- 餐點Id 
            ( 
                SELECT TOP 1 Dir 
                FROM S_UploadFile SUF 
                WHERE SUF.enterpriseid = FP.EnterpriseID AND SUF.itemid = FP.ID 
            ) AS ImagePath,                   -- 餐點照片路徑 
            FP.name AS FoodName,              -- 餐點名稱 
        --  ISNULL(JSON_VALUE(LANGFOOD.Content, '$.TW.Name'), FP.name) AS FoodNameMultiLang, -- 多語系餐點名稱(固定TW) 
            PDE.introduce AS Description,     -- 餐點描述 
            CAST(0 AS Bit) AS IsCombo,        -- 是否為套餐 
            FP.price AS Price,                -- 單價 
            K1.Sn AS Sort,                    -- 排序 
            -- 使用CASE避免空陣列格式問題 
            CASE  
                WHEN EXISTS ( 
                    SELECT 1 
                    FROM p_agiokind gkind_inner 
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
                        AND afmould.id = FP.id 
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
                            AND afmould.id = FP.id 
                        FOR XML PATH('') 
                    ), 1, 1, ''),  
                ']') 
                ELSE '[]' 
            END AS PromotionList,           -- 優惠活動列表 
            ISNULL( 
            ( 
                SELECT TOP 1 gkind.Name 
                FROM  
                    p_agiokind gkind 
                    JOIN P_AgioItems aitem  
                        ON gkind.EnterpriseID = aitem.EnterpriseID 
                        AND gkind.id = aitem.AgioKind 
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
                    gkind.EnterpriseID = @enterpriseId 
                    AND ashop.shopid = @shopId 
                    AND aitem.DiscountKind IN ('ASinglePercent', 'AsingleCost') 
                    AND afmould.id = FP.id 
            ),'' 
            ) AS PromotionBadge,              -- 優惠Badge 
            CAST(CASE WHEN FP.stop = 1 THEN 1 ELSE 0 END AS Bit) AS IsSoldOut  -- 是否停售 
        FROM  
            P_FoodMould_Shop fshop 
            JOIN P_FoodMould_M fm  
                ON fshop.enterpriseid = fm.enterpriseid 
                AND fshop.mouldcode = fm.MouldCode 
                AND fm.status = 9 
            JOIN P_foodMould FP  
                ON fm.enterpriseid = FP.EnterpriseID 
                AND fm.mouldcode = fp.MouldCode 
                AND FP.YSFlag <> 1  
                AND FP.YSFlag IS NOT NULL 
            JOIN P_FoodKind_Mould K1  
                ON K1.EnterpriseID = fshop.EnterPriseID 
                AND K1.MouldCode = fm.MouldCode 
                AND k1.id = fp.kind 
            JOIN p_foodkind2 K2  
                ON K2.EnterpriseID = K1.EnterpriseID 
                AND K2.ID = FP.kind2 
                AND k2.id = k1.FLevel 
            JOIN P_FOOD PDE  
                ON PDE.id = FP.id 
            LEFT JOIN P_Data_Language_D LANGKIND  
                ON LANGKIND.EnterpriseID = @enterpriseId  
                AND LANGKIND.SourceID = K1.ID  
                AND LANGKIND.TableName = 'FoodKind' 
            LEFT JOIN P_Data_Language_D LANGFOOD  
                ON LANGFOOD.EnterpriseID = @enterpriseId  
                AND LANGFOOD.SourceID = FP.ID 
                AND LANGFOOD.TableName = 'Food' 
            -- 關聯訂單類型對應的表 
            LEFT JOIN P_FoodMould_M FMO 
                ON FMO.EnterpriseID = FP.EnterpriseID 
                AND FMO.MouldType in (2,5,6) 
                and fmo.MouldCode=fshop.MouldCode 
        WHERE  
            fshop.enterpriseid = @enterpriseId 
            AND fshop.shopid = @shopId 
            AND (@categoryId IS NULL OR K1.ID = @categoryId) 
            AND (@orderType IS NULL  
                 OR EXISTS ( 
                    SELECT 1  
                     FROM P_FoodMould_M FMO 
                     WHERE FMO.EnterpriseID = FP.EnterpriseID 
                           --AND FMO.FoodID = FP.ID 
                           AND FMO.MouldType in (2,5,6) 
                           and fmo.MouldCode=fshop.MouldCode 
                 ) 
            ) 
        ORDER BY  
            FoodCategoryId, Sort; 
    END TRY 
    BEGIN CATCH 
        -- 錯誤處理 
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