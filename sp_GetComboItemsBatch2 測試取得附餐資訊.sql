SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_GetComboItemsBatch2]    
    @enterpriseId NVARCHAR(50),    
    @shopId NVARCHAR(50),    
    @foodIds NVARCHAR(MAX),    
    @orderType NVARCHAR(50),    
    @langId NVARCHAR(50)    
AS    
   
-- DECLARE @enterpriseId NVARCHAR(50) = 'xurf',    
--     @shopId NVARCHAR(50) = 'A001',    
--     @foodIds NVARCHAR(MAX) = 'la0134050',    
--     @orderType NVARCHAR(50) = 'scaneDesk',    
--     @langId NVARCHAR(50) = 'TW';   
   
BEGIN    
    SET NOCOUNT ON;    
        
    -- 宣告時段菜單變數
    DECLARE @useTimeBasedMenu BIT = 0;
    DECLARE @currentWeekDay INT;
    DECLARE @currentTime TIME;
    
    -- 如果訂單類型是 scaneDesk，檢查是否需要使用時段菜單
    IF @orderType = 'scaneDesk'
    BEGIN
        -- 取得當前星期和時間
        SET @currentWeekDay = DATEPART(WEEKDAY, GETDATE());
        SET @currentTime = CAST(GETDATE() AS TIME);
        
        -- 檢查是否使用時段菜單
        SELECT @useTimeBasedMenu = CASE 
            WHEN ParameterValue = 'true' THEN 1 
            ELSE 0 
        END
        FROM S_Parameter_Enterprise 
        WHERE EnterPriseID = @enterpriseId 
            AND ParameterGID = '79dabbec-a224-4f34-a13e-04540c9d548e';
    END
        
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
                AND PF.MouldCode = COALESCE(fm.MouldCode, fmt.MouldCode)   
                AND PF.Kind = PEK.KindID  
                AND (PF.Stop = 0 OR PF.Stop IS NULL)  
            LEFT JOIN S_UploadFile SUF   
                ON ENT.EnterpriseID = SUF.EnterpriseID   
                AND SUF.ItemID = ENT.EntFood    
                AND SUF.vType = 'food2'    
            LEFT JOIN P_Data_Language_D LANGFOOD    
                ON LANGFOOD.EnterpriseID = @enterpriseid    
                AND LANGFOOD.SourceID = ENT.EntFood   
                AND LANGFOOD.TableName = 'Food'  
            -- POS 商品售完   
            LEFT JOIN P_FoodMouldJoin PFMJ on PFMJ.EnterpriseID = @enterpriseId and PFMJ.MouldCode = COALESCE(fm.MouldCode, fmt.MouldCode) and PFMJ.FoodID = ENT.EntFood and PFMJ.ShopID = @shopId  
            WHERE ENT.EnterpriseID = @enterpriseId    
                AND ENT.MainFood = F.FoodId   
                AND ENT.MouldCode = COALESCE(fm.MouldCode, fmt.MouldCode)   
                AND ENT.EntFood IS NOT NULL    
            ORDER BY ENT.EntNo    
            FOR JSON PATH    
        ) AS FoodItems,    
        PEK.MaxCount AS MaxSelectCount,    
        PEK.MinCount AS MinSelectCount,    
        PEK.EntKindNo AS Sort, 
        PEK.[Group] AS [Group] 
    FROM @FoodIdsTable F   
    -- 先透過 P_FoodMould_M 以及 P_FoodMould_Shop 確定要取的菜單 MouldCode   
    JOIN P_FoodMould_Shop fshop ON fshop.EnterpriseID = @enterpriseId AND fshop.ShopID = @shopId
    -- 關聯菜單主檔 - 根據是否使用時段菜單選擇不同的表
    LEFT JOIN P_FoodMould_M fm ON @useTimeBasedMenu = 0
        AND fm.EnterpriseID = @enterpriseId   
        AND fm.[Status] = 9   
        AND fm.MouldCode = fshop.MouldCode
        AND fm.MouldType = CASE @orderType          
            WHEN 'takeout' THEN 2      
            WHEN 'homeDelivery' THEN 3    
            WHEN 'delivery' THEN 5           
            WHEN 'scaneDesk' THEN 6          
        END    
    -- 如果使用時段菜單，則關聯 P_FoodMould_M_Time 表進行時間篩選
    LEFT JOIN P_FoodMould_M_Time fmt ON @useTimeBasedMenu = 1 
        AND fmt.EnterpriseID = @enterpriseId 
        AND fmt.MouldCode = fshop.MouldCode
        AND (
            -- 檢查星期是否符合
            (@currentWeekDay = 2 AND fmt.Week1 = 1) OR
            (@currentWeekDay = 3 AND fmt.Week2 = 1) OR
            (@currentWeekDay = 4 AND fmt.Week3 = 1) OR
            (@currentWeekDay = 5 AND fmt.Week4 = 1) OR
            (@currentWeekDay = 6 AND fmt.Week5 = 1) OR
            (@currentWeekDay = 7 AND fmt.Week6 = 1) OR
            (@currentWeekDay = 1 AND fmt.Week7 = 1)
        )
        AND (
            -- 檢查時間是否符合任一時間區段
            (@currentTime BETWEEN fmt.BeginTime1 AND fmt.EndTime1) OR
            (@currentTime BETWEEN fmt.BeginTime2 AND fmt.EndTime2) OR
            (@currentTime BETWEEN fmt.BeginTime3 AND fmt.EndTime3)
        )   
    -- 取得*小類*的資訊與數量設定   
    JOIN P_FoodEntKind_Mould PEK ON PEK.EnterpriseID = @enterpriseId AND PEK.MouldCode = COALESCE(fm.MouldCode, fmt.MouldCode) AND PEK.FoodID = F.FoodId   
    LEFT JOIN P_Data_Language_D LANGKIND   
        ON LANGKIND.EnterpriseID = @enterpriseid   
        AND LANGKIND.SourceID = PEK.KindID   
        AND LANGKIND.TableName = 'FoodKind'
    LEFT JOIN  P_FoodKind PFK ON PFK.EnterpriseID = @enterpriseId AND PFK.ID = PEK.KindID
    ORDER BY F.FoodId, PEK.EntKindNo    
END
GO
