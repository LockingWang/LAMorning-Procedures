-- 參數設定
DECLARE @UserCode VARCHAR(50) = 'Harry';
DECLARE @Style VARCHAR(8) = '#FFFFFF';
DECLARE @PreviewMode BIT = 0;  -- 1=預覽只列資料, 0=實際插入
SET XACT_ABORT ON;

-- 清理暫存表
IF OBJECT_ID('tempdb..#base_data') IS NOT NULL DROP TABLE #base_data;
IF OBJECT_ID('tempdb..#new_ent') IS NOT NULL DROP TABLE #new_ent;
IF OBJECT_ID('tempdb..#new_kind') IS NOT NULL DROP TABLE #new_kind;
IF OBJECT_ID('tempdb..#ent_source') IS NOT NULL DROP TABLE #ent_source;
IF OBJECT_ID('tempdb..#new_ent_mould') IS NOT NULL DROP TABLE #new_ent_mould;

-- 基礎資料（需新增的 PriceExpr/Enterprise/主餐/模組）
SELECT DISTINCT
  food.PriceExpr,
  ent.EnterpriseID,
  ent.MainFood,
  ent.MouldCode,
  base.Price,
  base.Sn
INTO #base_data
FROM P_FoodEnt_Mould ent
LEFT JOIN P_Food food
  ON food.ID = ent.EntFood
 AND food.EnterpriseID = ent.EnterpriseID           -- 多價位附餐主檔
LEFT JOIN P_Food base
  ON base.ID = food.PriceExpr
 AND base.EnterpriseID = ent.EnterpriseID           -- 多價位頭檔（原商品）
LEFT JOIN P_FoodMould_M mould ON mould.EnterpriseID = ent.EnterpriseID AND mould.MouldCode = ent.MouldCode
LEFT JOIN P_FoodMould_M_Time timeMould ON timeMould.EnterpriseID = ent.EnterpriseID AND timeMould.MouldCode = ent.MouldCode
WHERE (
        (mould.[Status] = '9' AND mould.MouldType IN ('2','3','5','6'))
        OR (timeMould.[Status] = '9' AND timeMould.MouldType IN ('2','3','5','6'))
    )
  AND food.PriceExpr <> '1'
  AND food.PriceExpr <> ''
  AND NOT EXISTS (
    SELECT 1
    FROM P_FoodEnt_Mould ent2
    WHERE ent2.EntFood = food.PriceExpr
      AND ent2.MainFood = ent.MainFood
      AND ent2.MouldCode = ent.MouldCode
      AND ent2.EnterpriseID = ent.EnterpriseID
  );

-- 準備 P_FoodEnt 欲新增資料
SELECT
  bd.EnterpriseID,
  NEWID() AS GID,
  bd.MainFood,
  bd.PriceExpr AS EntFood,
  bd.Price,
  1 AS Count,
  0 AS Auto,
  0 AS Def,
  1 AS IsDeskOrder,
  1 AS IsPadOrder,
  1 AS IsAppOrder,
  bd.Sn AS EntNo,
  @UserCode AS LastOP,
  GETDATE() AS LastModify,
  @Style AS Style,
  NULL AS ShopID,
  NULL AS Kind
INTO #new_ent
FROM #base_data bd
WHERE NOT EXISTS (
  SELECT 1
  FROM P_FoodEnt existing
  WHERE existing.EnterpriseID = bd.EnterpriseID
    AND existing.MainFood = bd.MainFood
    AND existing.EntFood = bd.PriceExpr
);
;WITH dedup AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY EnterpriseID, MainFood, EntFood ORDER BY GID) AS rn
  FROM #new_ent
)
DELETE FROM dedup WHERE rn > 1;

-- 準備 P_FoodEntKind_Mould 欲新增資料
SELECT NEWID() AS GID, kind.EnterpriseID, kind.KindID, bd.MouldCode, bd.MainFood AS FoodID, kind.MaxCount, kind.MinCount, kind.[Group], kind.ShopID, @UserCode AS LastOP, GETDATE() AS LastModify, kind.EntKindNo, kind.IsDeskOrder, kind.IsPadOrder, kind.KindName
INTO #new_kind
FROM #base_data bd
JOIN P_FoodEntKind kind
  ON kind.EnterpriseID = bd.EnterpriseID
 AND kind.FoodID = bd.MainFood
WHERE NOT EXISTS (
  SELECT 1
  FROM P_FoodEntKind_Mould existing
  WHERE existing.EnterpriseID = kind.EnterpriseID
    AND existing.KindID = kind.KindID
    AND existing.MouldCode = bd.MouldCode
    AND existing.FoodID = bd.MainFood
);
;WITH dedup AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY EnterpriseID, KindID, MouldCode, FoodID ORDER BY GID) AS rn
  FROM #new_kind
)
DELETE FROM dedup WHERE rn > 1;

-- 來源資料（既有 + 新增的 P_FoodEnt）
SELECT EnterpriseID, MainFood, EntFood, Count, Price, [Auto], Def, EntNo, ShopID, IsDeskOrder, IsPadOrder, Kind, IsAppOrder, Style
INTO #ent_source
FROM P_FoodEnt
WHERE EntFood IN (SELECT PriceExpr FROM #base_data)
  AND MainFood IN (SELECT MainFood FROM #base_data)
  AND EnterpriseID IN (SELECT EnterpriseID FROM #base_data);

INSERT INTO #ent_source
SELECT EnterpriseID, MainFood, EntFood, Count, Price, [Auto], Def, EntNo, ShopID, IsDeskOrder, IsPadOrder, Kind, IsAppOrder, Style
FROM #new_ent;
;WITH dedup AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY EnterpriseID, MainFood, EntFood ORDER BY EntNo) AS rn
  FROM #ent_source
)
DELETE FROM dedup WHERE rn > 1;

-- 準備 P_FoodEnt_Mould 欲新增資料
SELECT NEWID() AS GID, src.EnterpriseID, bd.MouldCode, src.MainFood, src.EntFood, src.Count, src.Price, src.[Auto], src.Def, src.EntNo, src.ShopID, @UserCode AS LastOP, GETDATE() AS LastModify, src.IsDeskOrder, src.IsPadOrder, src.Kind, src.IsAppOrder, ISNULL(src.Style, @Style) AS Style
INTO #new_ent_mould
FROM #base_data bd
JOIN #ent_source src
  ON src.EnterpriseID = bd.EnterpriseID
 AND src.MainFood = bd.MainFood
 AND src.EntFood = bd.PriceExpr
WHERE NOT EXISTS (
  SELECT 1
  FROM P_FoodEnt_Mould existing
  WHERE existing.EnterpriseID = src.EnterpriseID
    AND existing.MouldCode = bd.MouldCode
    AND existing.MainFood = src.MainFood
    AND existing.EntFood = src.EntFood
);
;WITH dedup AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY EnterpriseID, MouldCode, MainFood, EntFood ORDER BY GID) AS rn
  FROM #new_ent_mould
)
DELETE FROM dedup WHERE rn > 1;

-- 預覽或執行
IF @PreviewMode = 1
BEGIN
  PRINT '預覽模式：僅列出即將插入的資料，不執行寫入';
  SELECT 'P_FoodEnt' AS TargetTable, * FROM #new_ent;
  SELECT 'P_FoodEntKind_Mould' AS TargetTable, * FROM #new_kind;
  SELECT 'P_FoodEnt_Mould' AS TargetTable, * FROM #new_ent_mould;
END
ELSE
BEGIN
  BEGIN TRY
    BEGIN TRAN;

    INSERT INTO P_FoodEnt(EnterpriseID,GID,MainFood,EntFood,Price,Count,Auto,Def,IsDeskOrder,IsPadOrder,IsAppOrder,EntNo,LastOP, LastModify,Style)
    SELECT EnterpriseID,GID,MainFood,EntFood,Price,Count,Auto,Def,IsDeskOrder,IsPadOrder,IsAppOrder,EntNo,LastOP,LastModify,Style
    FROM #new_ent;

    INSERT INTO P_FoodEntKind_Mould(GID,EnterpriseID,KindID,MouldCode,FoodID,MaxCount,MinCount,[Group],ShopID,LastOP,LastModify,EntKindNo,IsDeskOrder,IsPadOrder,KindName)
    SELECT GID,EnterpriseID,KindID,MouldCode,FoodID,MaxCount,MinCount,[Group],ShopID,LastOP,LastModify,EntKindNo,IsDeskOrder,IsPadOrder,KindName
    FROM #new_kind;

    INSERT INTO P_FoodEnt_Mould(GID,EnterpriseID,MouldCode,MainFood,EntFood,Count,Price,[Auto],Def,EntNo,ShopID,LastOP,LastModify,IsDeskOrder,IsPadOrder,Kind,IsAppOrder,Style)
    SELECT GID,EnterpriseID,MouldCode,MainFood,EntFood,Count,Price,[Auto],Def,EntNo,ShopID,LastOP,LastModify,IsDeskOrder,IsPadOrder,Kind,IsAppOrder,Style
    FROM #new_ent_mould;

    COMMIT TRAN;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    THROW;
  END CATCH
END

-- 清理暫存表
DROP TABLE IF EXISTS #new_ent_mould;
DROP TABLE IF EXISTS #ent_source;
DROP TABLE IF EXISTS #new_kind;
DROP TABLE IF EXISTS #new_ent;
DROP TABLE IF EXISTS #base_data;