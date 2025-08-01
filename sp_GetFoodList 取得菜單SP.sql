CREATE   PROCEDURE [dbo].[sp_GetFoodList]          
    @enterpriseId NVARCHAR(50),    -- 企業ID          
    @shopId NVARCHAR(50),          -- 店鋪ID           
    @categoryId NVARCHAR(50),      -- 分類ID（目前未使用）          
    @orderType NVARCHAR(50),       -- 訂單類型         
    @langId NVARCHAR(50),          -- 語系ID          
    @foodId NVARCHAR(50) = NULL    -- 食品ID      
AS         
     
-- 測試用         
-- DECLARE @enterpriseId NVARCHAR(50) = 'xurf'     -- 企業ID          
-- DECLARE @shopId NVARCHAR(50) = 'A002'                -- 店鋪ID           
-- DECLARE @categoryId NVARCHAR(50) = ''               -- 分類ID（目前未使用）          
-- DECLARE @orderType NVARCHAR(50) = 'takeout'       -- 訂單類型       
-- DECLARE @langId NVARCHAR(50) = 'TW'                 -- 語系ID          
-- DECLARE @foodId NVARCHAR(50) = NULL                 -- 食品ID      
     
     
BEGIN          
    SET NOCOUNT ON;          
          
    BEGIN TRY          
          
SELECT          
    FM.Kind AS FoodCategoryId,  -- 食品分類ID          
    ISNULL(JSON_VALUE(LANGKIND.Content, '$.' + @langId + '.Name'), FK.Name) AS FoodCategoryName,  -- 食品分類名稱（多語系）         
    FK.Sn AS FoodCategorySort,  -- 食品分類排序          
    FM.ID AS FoodId,            -- 食品ID          
    ISNULL(JSON_VALUE(LANGFOOD.Content, '$.' + @langId + '.Name'), FM.Name) AS FoodName,          -- 食品名稱（多語系）          
    (           
        -- 取食品圖片路徑（僅取一筆）          
        SELECT TOP 1 Dir           
        FROM S_UploadFile UF          
        WHERE UF.enterpriseid = @enterpriseId AND UF.itemid = FM.ID           
    ) AS ImagePath,          
    F.Introduce AS Description, -- 食品描述          
    CASE WHEN FM.YSFlag = 1 THEN 1 ELSE 0 END AS IsCombo,  -- 是否為套餐（YSFlag=1為套餐，0為單品）          
    FM.price AS Price,           -- 價格     
    -- 套餐升級清單（找出包含當前商品的套餐）     
    CASE      
        WHEN FM.YSFlag = 0 THEN  -- 只有單品才需要找套餐     
            CONCAT('[',      
                STUFF((     
                    SELECT DISTINCT     
                        ',{"FoodId":"' + CAST(PFM.ID AS NVARCHAR(50)) + '","FoodName":"' + ISNULL(JSON_VALUE(LANGPFM.Content, '$.' + @langId + '.Name'), PFM.Name) + '","Price":' + CAST(PFM.price AS NVARCHAR(20)) + '}'     
                    FROM P_FoodEnt_Mould PFEM     
                    JOIN P_FoodMould PFM ON PFM.EnterpriseID = @enterpriseId      
                        AND PFM.MouldCode = PFEM.MouldCode    
                        AND PFM.YSFlag = 1  -- 只找套餐     
                        AND PFM.ID = PFEM.MainFood    
                        AND PFM.Hide = 0   
                    JOIN P_FoodKind_Mould FKM ON FKM.EnterpriseID = @enterpriseId    
                        AND FKM.ID = PFM.Kind    
                        AND FKM.MouldCode = PFEM.MouldCode  
                    LEFT JOIN P_Data_Language_D LANGPFM ON LANGPFM.EnterpriseID = @enterpriseId    
                        AND LANGPFM.SourceID = PFM.ID    
                        AND LANGPFM.TableName = 'Food'    
                    WHERE PFEM.EnterpriseID = @enterpriseId    
                        AND PFEM.MouldCode = FMS.MouldCode    
                        AND PFEM.EntFood = FM.ID  -- 找出包含當前商品的套餐     
                    FOR XML PATH('')     
                ), 1, 1, ''),     
            ']')     
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
    ISNULL(PFMJ.Stop,0) AS IsSoldOut   
FROM P_FoodMould_Shop FMS          
    -- 關聯菜單主檔          
    JOIN P_FoodMould_M FMM ON FMM.EnterPriseID = @enterpriseId           
        AND FMM.MouldCode = FMS.MouldCode           
        AND FMM.[Status] = 9          
        AND FMM.MouldType = CASE @orderType          
            WHEN 'takeout' THEN 2          
            WHEN 'delivery' THEN 5           
            WHEN 'scaneDesk' THEN 6          
        END  
    -- 關聯菜單食品主檔（過濾掉停售、隱藏商品）          
    JOIN P_FoodMould FM ON FM.EnterPriseID = @enterpriseId AND FM.MouldCode = FMS.MouldCode AND (FM.stop = 0 OR FM.stop IS NULL) AND FM.Hide = 0     
    -- 關聯食品小分類 ( 過濾掉隱藏小分類 )      
    JOIN P_FoodKind_Mould FK ON FK.EnterpriseID = @enterpriseId AND FK.ID = FM.Kind AND FK.MouldCode = FMM.MouldCode AND (FK.Hide = 0 or @foodId is not null)       
    -- 關聯食品資料  
    JOIN P_Food F ON F.EnterpriseID = @enterpriseId AND F.Kind = FM.Kind AND F.ID = FM.ID  
    -- 多語系：食品小分類  
    LEFT JOIN P_Data_Language_D LANGKIND ON LANGKIND.EnterpriseID = @enterpriseid AND LANGKIND.SourceID = FM.Kind AND LANGKIND.TableName = 'FoodKind'          
    -- 多語系：食品名稱  
    LEFT JOIN P_Data_Language_D LANGFOOD ON LANGFOOD.EnterpriseID = @enterpriseid AND LANGFOOD.SourceID = FM.ID AND LANGFOOD.TableName = 'Food'      
    -- 商品停售  
    LEFT JOIN P_FoodMouldJoin PFMJ on FM.EnterpriseID = PFMJ.EnterpriseID and FM.MouldCode = PFMJ.MouldCode and FM.ID = PFMJ.FoodID and PFMJ.ShopID = @shopId  
WHERE FMS.EnterPriseID = @enterpriseId  
    AND FMS.ShopID = @shopId      
    AND (@foodId IS NULL OR FM.ID = @foodId)      
ORDER BY FoodCategoryId, Sort 
OPTION(RECOMPILE) 
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