-- 宣告變數
DECLARE @PriceExpr VARCHAR(100)
DECLARE @CurrentEnterpriseID VARCHAR(100)  -- 當前處理的企業號
DECLARE @MouldCode VARCHAR(100)
DECLARE @MouldType INT
DECLARE @type INT
DECLARE @Kind VARCHAR(100)
DECLARE @UserCode VARCHAR(100) = 'Harry'
DECLARE @PreviewMode BIT = 0  -- 預覽模式：0=執行插入, 1=僅預覽
DECLARE @FoodMouldCount INT
DECLARE @FoodAddMouldCount INT
DECLARE @TotalFoodMouldCount INT = 0  -- 總計新增的商品主檔數量
DECLARE @TotalFoodAddMouldCount INT = 0  -- 總計新增的註記數量

IF @PreviewMode = 1
BEGIN
    PRINT '==========================================='
    PRINT '預覽模式：僅顯示預計要插入的資料，不會執行實際插入'
    PRINT '將處理所有企業號的資料'
    PRINT '==========================================='
END
ELSE
BEGIN
    PRINT '==========================================='
    PRINT '執行模式：將處理所有企業號的資料'
    PRINT '==========================================='
END

-- 建立臨時表來記錄新增的資料（或預覽資料）
CREATE TABLE #InsertedFoodMould (
    GID UNIQUEIDENTIFIER,
    EnterpriseID VARCHAR(100),
    MouldCode VARCHAR(100),
    ID VARCHAR(100),
    Name NVARCHAR(200),  -- 使用 NVARCHAR 以支援 Unicode 字元（中文等）
    PriceExpr VARCHAR(100)
)

CREATE TABLE #InsertedFoodAddMould (
    GID UNIQUEIDENTIFIER,
    EnterpriseID VARCHAR(100),
    MouldCode VARCHAR(100),
    ID VARCHAR(100),
    Owner VARCHAR(100),
    Name NVARCHAR(200),  -- 使用 NVARCHAR 以支援 Unicode 字元（中文等）
    AddType NVARCHAR(20)  -- '商品註記' 或 '類別註記' - 使用 NVARCHAR 以支援中文
)

-- 如果不是預覽模式，才開始交易
IF @PreviewMode = 0
BEGIN
    BEGIN TRANSACTION
END

BEGIN TRY

-- 外層 CURSOR：遍歷所有不同的企業號
DECLARE cur_enterprise CURSOR FOR
SELECT DISTINCT f1.EnterpriseID
FROM P_FoodMould f1
LEFT JOIN P_FoodMould_M mould ON mould.EnterpriseID = f1.EnterpriseID AND mould.MouldCode = f1.MouldCode
LEFT JOIN P_FoodMould_M_Time timeMould ON timeMould.EnterpriseID = f1.EnterpriseID AND timeMould.MouldCode = f1.MouldCode
WHERE f1.PriceExpr <> '' 
    AND f1.PriceExpr <> '1'
    AND EXISTS (
        SELECT 1 
        FROM P_Food food_check
        WHERE food_check.EnterpriseID = f1.EnterpriseID
        AND food_check.ID = f1.ID
    )
    AND EXISTS (
        SELECT 1 
        FROM P_Food food_check2
        WHERE food_check2.EnterpriseID = f1.EnterpriseID
        AND food_check2.ID = f1.PriceExpr
    )
    AND NOT EXISTS (
        SELECT 1 
        FROM P_FoodMould f2
        WHERE f2.EnterpriseID = f1.EnterpriseID
        AND f2.MouldCode = f1.MouldCode
        AND f2.ID = f1.PriceExpr
    )
    AND (
        (mould.[Status] = '9' AND mould.MouldType IN ('2','3','5','6'))
        OR (timeMould.[Status] = '9' AND timeMould.MouldType IN ('2','3','5','6'))
    )
ORDER BY f1.EnterpriseID

-- 開啟外層 CURSOR
OPEN cur_enterprise
FETCH NEXT FROM cur_enterprise INTO @CurrentEnterpriseID

-- 開始迴圈處理每個企業號
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT ''
    PRINT '開始處理企業號: ' + @CurrentEnterpriseID
    
    -- 清空臨時表（每個企業號重新開始）
    DELETE FROM #InsertedFoodMould
    DELETE FROM #InsertedFoodAddMould
    
    -- 內層 CURSOR：處理該企業號下的所有資料
    DECLARE cur_data CURSOR FOR
    SELECT DISTINCT 
        f1.PriceExpr,
        f1.MouldCode,
        COALESCE(mould.MouldType, timeMould.MouldType)
    FROM P_FoodMould f1
    LEFT JOIN P_FoodMould_M mould ON mould.EnterpriseID = f1.EnterpriseID AND mould.MouldCode = f1.MouldCode
    LEFT JOIN P_FoodMould_M_Time timeMould ON timeMould.EnterpriseID = f1.EnterpriseID AND timeMould.MouldCode = f1.MouldCode
    WHERE f1.EnterpriseID = @CurrentEnterpriseID
        AND f1.PriceExpr <> '' 
        AND f1.PriceExpr <> '1'
        AND EXISTS (
            SELECT 1 
            FROM P_Food food_check
            WHERE food_check.EnterpriseID = f1.EnterpriseID
            AND food_check.ID = f1.ID
        )
        AND EXISTS (
            SELECT 1 
            FROM P_Food food_check2
            WHERE food_check2.EnterpriseID = f1.EnterpriseID
            AND food_check2.ID = f1.PriceExpr
        )
        AND NOT EXISTS (
            SELECT 1 
            FROM P_FoodMould f2
            WHERE f2.EnterpriseID = f1.EnterpriseID
            AND f2.MouldCode = f1.MouldCode
            AND f2.ID = f1.PriceExpr
        )
        AND (
            (mould.[Status] = '9' AND mould.MouldType IN ('2','3','5','6'))
            OR (timeMould.[Status] = '9' AND timeMould.MouldType IN ('2','3','5','6'))
        )

    -- 開啟內層 CURSOR
    OPEN cur_data
    FETCH NEXT FROM cur_data INTO @PriceExpr, @MouldCode, @MouldType

    -- 開始迴圈處理該企業號下的每一筆資料
    WHILE @@FETCH_STATUS = 0
    BEGIN
    -- 設定 type 變數
    SET @type = @MouldType
    
    -- 先新增商品主檔到菜單中
    IF(@type = 0 OR @type = 9 OR @type = 4 OR @type = 8)
    BEGIN
        IF @PreviewMode = 0
        BEGIN
            -- 實際執行插入
            INSERT INTO P_FoodMould(GID,EnterpriseID,MouldCode,ID,No,Name,PDAName,EName,Kind,Unit,Price,EntCount,CurPrice,Stop,ServCost,Discount,TotalDiscount,NoKindEnt,NoKindPrint,NoGroup,NoKindPriceKind,Special,Special1,PriceReason,Counteract,PriceExpr,ManCount,FreeCount,FreePrice,EntPriceKind,Hide,ShowSeg,InputForm,PubName,UseAs,BarCode,ShopID,LastOP,LastModify,ChangePrice,PYCode,BoxType,RoomPrice,CostPrice,Kind2,FoodType,SuitePrice,CanMaterial,CanSplit,SubTotal,SvrID,SupplyCode,CanPromotion,StartTime,StopTime,CK_AgioCost,IsExchange,ExchangeInteger,FUnitPak,FPakCoef,FUnitAsk,Days,YSFlag,BPrice,curcost,BZSaleType,CFlag,IsShelf,ShelfBgnDate,ShelfEndDate,IsPublic,NotAutoEntForm,isgpa,JDCount,precount,JDCount1,ISJin,IsKDS,FoodIDSAP,IsDeskOrder,IsPadOrder,IsAppOrder,Sn,Points,ErpID,KDSStationID,KdsOutOverMin,KdsEndOverMin,PayDays,NoCounteract,Introduce,FreeTax,NoKindAdd,NoKindTaste,KDSTag,GradeProp,CustomEnt,Style)
            OUTPUT INSERTED.GID, INSERTED.EnterpriseID, INSERTED.MouldCode, INSERTED.ID, INSERTED.Name, INSERTED.PriceExpr
            INTO #InsertedFoodMould
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,No,Name,PDAName,EName,Kind,Unit,Price,EntCount,CurPrice,Stop,ServCost,Discount,TotalDiscount,NoKindEnt,NoKindPrint,NoGroup,NoKindPriceKind,Special,Special1,PriceReason,Counteract,PriceExpr,ManCount,FreeCount,FreePrice,EntPriceKind,Hide,ShowSeg,InputForm,PubName,UseAs,BarCode,ShopID,@UserCode, GETDATE(),ChangePrice,PYCode,BoxType,RoomPrice,CostPrice,Kind2,FoodType,SuitePrice,CanMaterial,CanSplit,SubTotal,SvrID,SupplyCode,CanPromotion,StartTime,StopTime,CK_AgioCost,IsExchange,ExchangeInteger,FUnitPak,FPakCoef,FUnitAsk,Days,YSFlag,BPrice,curcost,BZSaleType,CFlag,IsShelf,ShelfBgnDate,ShelfEndDate,IsPublic,NotAutoEntForm,isgpa,JDCount,precount,JDCount1,ISJin,IsKDS,FoodIDSAP,IsDeskOrder,IsPadOrder,IsAppOrder,Sn,Points,ErpID,KDSStationID,KdsOutOverMin,KdsEndOverMin,PayDays,NoCounteract,Introduce,FreeTax,NoKindAdd,NoKindTaste,KDSTag,GradeProp,CustomEnt,IIF(Style IS NULL,'',Style) 
            FROM P_Food 
            WHERE EnterpriseID = @CurrentEnterpriseID AND ID = @PriceExpr
        END
        ELSE
        BEGIN
            -- 預覽模式：只記錄到臨時表
            INSERT INTO #InsertedFoodMould(GID,EnterpriseID,MouldCode,ID,Name,PriceExpr)
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,Name,@PriceExpr
            FROM P_Food 
            WHERE EnterpriseID = @CurrentEnterpriseID AND ID = @PriceExpr
        END
    END
    ELSE IF(@type = 2 OR @type = 5 OR @type = 6 OR @type = 3)
    BEGIN
        IF @PreviewMode = 0
        BEGIN
            -- 實際執行插入
            INSERT INTO P_FoodMould(GID,EnterpriseID,MouldCode,ID,No,Name,PDAName,EName,Kind,Unit,Price,EntCount,CurPrice,Stop,ServCost,Discount,TotalDiscount,NoKindEnt,NoKindPrint,NoGroup,NoKindPriceKind,Special,Special1,PriceReason,Counteract,PriceExpr,ManCount,FreeCount,FreePrice,EntPriceKind,Hide,ShowSeg,InputForm,PubName,UseAs,BarCode,ShopID,LastOP,LastModify,ChangePrice,PYCode,BoxType,RoomPrice,CostPrice,Kind2,FoodType,SuitePrice,CanMaterial,CanSplit,SubTotal,SvrID,SupplyCode,CanPromotion,StartTime,StopTime,CK_AgioCost,IsExchange,ExchangeInteger,FUnitPak,FPakCoef,FUnitAsk,Days,YSFlag,BPrice,curcost,BZSaleType,CFlag,IsShelf,ShelfBgnDate,ShelfEndDate,IsPublic,NotAutoEntForm,isgpa,JDCount,precount,JDCount1,ISJin,IsKDS,FoodIDSAP,IsDeskOrder,IsPadOrder,IsAppOrder,Sn,Points,ErpID,KDSStationID,KdsOutOverMin,KdsEndOverMin,PayDays,NoCounteract,Introduce,FreeTax,NoKindAdd,NoKindTaste,KDSTag,GradeProp,CustomEnt,Style)
            OUTPUT INSERTED.GID, INSERTED.EnterpriseID, INSERTED.MouldCode, INSERTED.ID, INSERTED.Name, INSERTED.PriceExpr
            INTO #InsertedFoodMould
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,No,Name,PDAName,EName,Kind,Unit,Price,EntCount,CurPrice,Stop,ServCost,Discount,TotalDiscount,NoKindEnt,NoKindPrint,NoGroup,NoKindPriceKind,Special,Special1,PriceReason,Counteract,PriceExpr,ManCount,FreeCount,FreePrice,EntPriceKind,Hide,ShowSeg,InputForm,PubName,UseAs,BarCode,ShopID,@UserCode, GETDATE(),ChangePrice,PYCode,BoxType,RoomPrice,CostPrice,Kind2,FoodType,SuitePrice,CanMaterial,CanSplit,SubTotal,SvrID,SupplyCode,CanPromotion,StartTime,StopTime,CK_AgioCost,IsExchange,ExchangeInteger,FUnitPak,FPakCoef,FUnitAsk,Days,YSFlag,BPrice,curcost,BZSaleType,CFlag,IsShelf,ShelfBgnDate,ShelfEndDate,IsPublic,NotAutoEntForm,isgpa,JDCount,precount,JDCount1,ISJin,IsKDS,FoodIDSAP,IsDeskOrder,IsPadOrder,1,Sn,Points,ErpID,KDSStationID,KdsOutOverMin,KdsEndOverMin,PayDays,NoCounteract,Introduce,FreeTax,NoKindAdd,NoKindTaste,KDSTag,GradeProp,CustomEnt,IIF(Style IS NULL,'',Style) 
            FROM P_Food 
            WHERE EnterpriseID = @CurrentEnterpriseID AND ID = @PriceExpr
        END
        ELSE
        BEGIN
            -- 預覽模式：只記錄到臨時表
            INSERT INTO #InsertedFoodMould(GID,EnterpriseID,MouldCode,ID,Name,PriceExpr)
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,Name,@PriceExpr
            FROM P_Food 
            WHERE EnterpriseID = @CurrentEnterpriseID AND ID = @PriceExpr
        END
    END

    -- 再新增商品註記到菜單中
    IF(@type = 0)
    BEGIN
        IF @PreviewMode = 0
        BEGIN
            -- 實際執行插入
            INSERT INTO P_FoodAdd_Mould(GID,EnterpriseID,MouldCode,ID,Owner,Name,Price,AddKindID,SN,Style,LastOP, LastModify,IsMultiple)
            OUTPUT INSERTED.GID, INSERTED.EnterpriseID, INSERTED.MouldCode, INSERTED.ID, INSERTED.Owner, INSERTED.Name, '商品註記'
            INTO #InsertedFoodAddMould
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,Owner,Name,Price,AddKindID,SN,Style,@UserCode, GETDATE(), IsMultiple 
            FROM P_FoodAdd
            WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @PriceExpr
        END
        ELSE
        BEGIN
            -- 預覽模式：只記錄到臨時表
            INSERT INTO #InsertedFoodAddMould(GID,EnterpriseID,MouldCode,ID,Owner,Name,AddType)
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,Owner,Name,'商品註記'
            FROM P_FoodAdd
            WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @PriceExpr
        END
    END
    ELSE IF(@type = 9 OR @type = 4 OR @type = 8)
    BEGIN
        IF @PreviewMode = 0
        BEGIN
            -- 實際執行插入
            INSERT INTO P_FoodAdd_Mould(GID,EnterpriseID,MouldCode,ID,Owner,Name,Price,AddKindID,SN,Style,LastOP, LastModify,IsMultiple)
            OUTPUT INSERTED.GID, INSERTED.EnterpriseID, INSERTED.MouldCode, INSERTED.ID, INSERTED.Owner, INSERTED.Name, '商品註記'
            INTO #InsertedFoodAddMould
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,Owner,Name,Price,AddKindID,SN,Style,@UserCode, GETDATE(),IsMultiple 
            FROM P_FoodAdd
            WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @PriceExpr AND ISNULL(IsPadOrder,'0') <> '1'
        END
        ELSE
        BEGIN
            -- 預覽模式：只記錄到臨時表
            INSERT INTO #InsertedFoodAddMould(GID,EnterpriseID,MouldCode,ID,Owner,Name,AddType)
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,Owner,Name,'商品註記'
            FROM P_FoodAdd
            WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @PriceExpr AND ISNULL(IsPadOrder,'0') <> '1'
        END
    END
    ELSE IF(@type = 2 OR @type = 5 OR @type = 6 OR @type = 3)
    BEGIN
        IF @PreviewMode = 0
        BEGIN
            -- 實際執行插入
            INSERT INTO P_FoodAdd_Mould(GID,EnterpriseID,MouldCode,ID,Owner,Name,Price,AddKindID,SN,Style,IsAppOrder,LastOP, LastModify,IsMultiple)
            OUTPUT INSERTED.GID, INSERTED.EnterpriseID, INSERTED.MouldCode, INSERTED.ID, INSERTED.Owner, INSERTED.Name, '商品註記'
            INTO #InsertedFoodAddMould
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,Owner,Name,Price,AddKindID,SN,Style,1,@UserCode, GETDATE(),IsMultiple 
            FROM P_FoodAdd
            WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @PriceExpr AND ISNULL(IsPadOrder,'0') <> '1'
        END
        ELSE
        BEGIN
            -- 預覽模式：只記錄到臨時表
            INSERT INTO #InsertedFoodAddMould(GID,EnterpriseID,MouldCode,ID,Owner,Name,AddType)
            SELECT NEWID(),EnterpriseID,@MouldCode,ID,Owner,Name,'商品註記'
            FROM P_FoodAdd
            WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @PriceExpr AND ISNULL(IsPadOrder,'0') <> '1'
        END
    END

    -- 最後新增類別註記到菜單中
    SET @Kind = (SELECT Kind FROM P_Food WHERE EnterpriseID = @CurrentEnterpriseID AND ID = @PriceExpr)

    IF NOT EXISTS (SELECT * FROM P_FoodAdd_Mould WHERE enterpriseid = @CurrentEnterpriseID AND Owner = @Kind AND MouldCode = @MouldCode)
    BEGIN
        IF(@type = 0)
        BEGIN
            IF @PreviewMode = 0
            BEGIN
                -- 實際執行插入
                INSERT INTO P_FoodAdd_Mould(GID,EnterpriseID,MouldCode,ID,KindID,Owner,Name,Price,X,Y,Style,Lock,Page,ShopID,LastOP,LastModify,AddKindID,IsDeskOrder,IsPadOrder,IsAppOrder,IsMultiple,SN,FoodID)
                OUTPUT INSERTED.GID, INSERTED.EnterpriseID, INSERTED.MouldCode, INSERTED.ID, INSERTED.Owner, INSERTED.Name, '類別註記'
                INTO #InsertedFoodAddMould
                SELECT NEWID(),EnterpriseID,@MouldCode,ID,KindID,Owner,Name,Price,X,Y,Style,Lock,Page,ShopID,@UserCode, GETDATE(),AddKindID,IsDeskOrder,IsPadOrder,IsAppOrder,IsMultiple,SN,FoodID
                FROM P_FoodAdd WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @Kind
            END
            ELSE
            BEGIN
                -- 預覽模式：只記錄到臨時表
                INSERT INTO #InsertedFoodAddMould(GID,EnterpriseID,MouldCode,ID,Owner,Name,AddType)
                SELECT NEWID(),EnterpriseID,@MouldCode,ID,Owner,Name,'類別註記'
                FROM P_FoodAdd WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @Kind
            END
        END
        ELSE IF(@type = 9 OR @type = 4 OR @type = 8)
        BEGIN
            IF @PreviewMode = 0
            BEGIN
                -- 實際執行插入
                INSERT INTO P_FoodAdd_Mould(GID,EnterpriseID,MouldCode,ID,KindID,Owner,Name,Price,X,Y,Style,Lock,Page,ShopID,LastOP,LastModify,AddKindID,IsDeskOrder,IsPadOrder,IsAppOrder,IsMultiple,SN,FoodID)
                OUTPUT INSERTED.GID, INSERTED.EnterpriseID, INSERTED.MouldCode, INSERTED.ID, INSERTED.Owner, INSERTED.Name, '類別註記'
                INTO #InsertedFoodAddMould
                SELECT NEWID(),EnterpriseID,@MouldCode,ID,KindID,Owner,Name,Price,X,Y,Style,Lock,Page,ShopID,@UserCode, GETDATE(),AddKindID,IsDeskOrder,IsPadOrder,IsAppOrder,IsMultiple,SN,FoodID
                FROM P_FoodAdd WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @Kind AND ISNULL(IsPadOrder,'0') <> '1'
            END
            ELSE
            BEGIN
                -- 預覽模式：只記錄到臨時表
                INSERT INTO #InsertedFoodAddMould(GID,EnterpriseID,MouldCode,ID,Owner,Name,AddType)
                SELECT NEWID(),EnterpriseID,@MouldCode,ID,Owner,Name,'類別註記'
                FROM P_FoodAdd WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @Kind AND ISNULL(IsPadOrder,'0') <> '1'
            END
        END
        ELSE IF(@type = 2 OR @type = 5 OR @type = 6 OR @type = 3)
        BEGIN
            IF @PreviewMode = 0
            BEGIN
                -- 實際執行插入
                INSERT INTO P_FoodAdd_Mould(GID,EnterpriseID,MouldCode,ID,KindID,Owner,Name,Price,X,Y,Style,Lock,Page,ShopID,LastOP,LastModify,AddKindID,IsDeskOrder,IsPadOrder,IsAppOrder,IsMultiple,SN,FoodID)
                OUTPUT INSERTED.GID, INSERTED.EnterpriseID, INSERTED.MouldCode, INSERTED.ID, INSERTED.Owner, INSERTED.Name, '類別註記'
                INTO #InsertedFoodAddMould
                SELECT NEWID(),EnterpriseID,@MouldCode,ID,KindID,Owner,Name,Price,X,Y,Style,Lock,Page,ShopID,@UserCode, GETDATE(),AddKindID,IsDeskOrder,IsPadOrder,1,IsMultiple,SN,FoodID
                FROM P_FoodAdd WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @Kind AND ISNULL(IsPadOrder,'0') <> '1'
            END
            ELSE
            BEGIN
                -- 預覽模式：只記錄到臨時表
                INSERT INTO #InsertedFoodAddMould(GID,EnterpriseID,MouldCode,ID,Owner,Name,AddType)
                SELECT NEWID(),EnterpriseID,@MouldCode,ID,Owner,Name,'類別註記'
                FROM P_FoodAdd WHERE EnterpriseID = @CurrentEnterpriseID AND Owner = @Kind AND ISNULL(IsPadOrder,'0') <> '1'
            END
        END
    END

    -- 取得下一筆資料
    FETCH NEXT FROM cur_data INTO @PriceExpr, @MouldCode, @MouldType
    END

    -- 關閉並釋放內層 CURSOR
    CLOSE cur_data
    DEALLOCATE cur_data
    
    -- 統計該企業號的資料
    SELECT @FoodMouldCount = COUNT(*) FROM #InsertedFoodMould
    SELECT @FoodAddMouldCount = COUNT(*) FROM #InsertedFoodAddMould
    
    -- 累計總計
    SET @TotalFoodMouldCount = @TotalFoodMouldCount + @FoodMouldCount
    SET @TotalFoodAddMouldCount = @TotalFoodAddMouldCount + @FoodAddMouldCount
    
    -- 顯示該企業號的處理結果
    IF @PreviewMode = 0
    BEGIN
        PRINT '完成處理企業號: ' + @CurrentEnterpriseID + ' (商品主檔: ' + CAST(@FoodMouldCount AS VARCHAR) + ' 筆, 註記: ' + CAST(@FoodAddMouldCount AS VARCHAR) + ' 筆)'
    END
    ELSE
    BEGIN
        PRINT '完成預覽企業號: ' + @CurrentEnterpriseID + ' (商品主檔: ' + CAST(@FoodMouldCount AS VARCHAR) + ' 筆, 註記: ' + CAST(@FoodAddMouldCount AS VARCHAR) + ' 筆)'
    END
    
    -- 取得下一個企業號
    FETCH NEXT FROM cur_enterprise INTO @CurrentEnterpriseID
END

-- 關閉並釋放外層 CURSOR
CLOSE cur_enterprise
DEALLOCATE cur_enterprise

-- 如果不是預覽模式，才提交交易
IF @PreviewMode = 0
BEGIN
    COMMIT TRANSACTION
    PRINT ''
    PRINT '==========================================='
    PRINT '所有企業號處理完成！'
    PRINT '==========================================='
    PRINT '總計新增商品主檔: ' + CAST(@TotalFoodMouldCount AS VARCHAR) + ' 筆'
    PRINT '總計新增註記: ' + CAST(@TotalFoodAddMouldCount AS VARCHAR) + ' 筆'
    PRINT '==========================================='
END
ELSE
BEGIN
    PRINT ''
    PRINT '==========================================='
    PRINT '所有企業號預覽完成！'
    PRINT '==========================================='
    PRINT '預計總計新增商品主檔: ' + CAST(@TotalFoodMouldCount AS VARCHAR) + ' 筆'
    PRINT '預計總計新增註記: ' + CAST(@TotalFoodAddMouldCount AS VARCHAR) + ' 筆'
    PRINT '==========================================='
    PRINT '注意：此為預覽模式，未執行實際插入操作'
    PRINT '==========================================='
END

END TRY
BEGIN CATCH
    -- 【唯一必修】發生錯誤時必須回滾交易
    DECLARE @HadTransaction BIT = 0
    IF @@TRANCOUNT > 0
    BEGIN
        SET @HadTransaction = 1
        ROLLBACK TRANSACTION
    END
    
    -- 顯示錯誤訊息
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()
    DECLARE @ErrorLine INT = ERROR_LINE()
    DECLARE @ErrorProcedure NVARCHAR(200) = ERROR_PROCEDURE()
    
    PRINT '==========================================='
    IF @HadTransaction = 1
    BEGIN
        PRINT '發生錯誤，所有修改已回滾 (ROLLBACK)'
    END
    ELSE
    BEGIN
        PRINT '發生錯誤（預覽模式或未開啟交易）'
    END
    PRINT '==========================================='
    PRINT '錯誤訊息: ' + @ErrorMessage
    PRINT '錯誤行號: ' + CAST(@ErrorLine AS VARCHAR)
    IF @ErrorProcedure IS NOT NULL
        PRINT '錯誤程序: ' + @ErrorProcedure
    PRINT '==========================================='
    
    -- 重新拋出錯誤
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH

-- 清理臨時表
IF OBJECT_ID('tempdb..#InsertedFoodMould') IS NOT NULL
    DROP TABLE #InsertedFoodMould

IF OBJECT_ID('tempdb..#InsertedFoodAddMould') IS NOT NULL
    DROP TABLE #InsertedFoodAddMould