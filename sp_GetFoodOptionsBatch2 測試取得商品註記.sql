SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_GetFoodOptionsBatch2]      
    @enterpriseId NVARCHAR(50),      
    @shopId NVARCHAR(50),      
    @foodIds NVARCHAR(MAX),      
    @orderType NVARCHAR(50),      
    @langId NVARCHAR(50)      
AS        
  
-- DECLARE      
--     @enterpriseId NVARCHAR(50) = 'xurf',       
--     @shopId NVARCHAR(50) = 'A001',     
--     @foodIds NVARCHAR(MAX) = 'la0134036',     
--     @orderType NVARCHAR(50) = 'scaneDesk',    
--     @langId NVARCHAR(50) = 'TW'       
     
     
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
    DECLARE @FoodIdsTable TABLE (FoodId NVARCHAR(50), FoodKind NVARCHAR(50))      
    INSERT INTO @FoodIdsTable (FoodId, FoodKind)     
    SELECT value, NULL FROM STRING_SPLIT(@foodIds, ',')      
     
    -- 根據 FoodId 更新 FoodKind 
    UPDATE F 
    SET F.FoodKind = PFM.Kind 
    FROM @FoodIdsTable F 
    JOIN P_FoodMould_Shop PFMS ON PFMS.EnterpriseID = @enterpriseId AND PFMS.ShopID = @shopId
    -- 關聯菜單主檔 - 根據是否使用時段菜單選擇不同的表
    LEFT JOIN P_FoodMould_M PFMM ON @useTimeBasedMenu = 0
        AND PFMM.EnterpriseID = @enterpriseId 
        AND PFMM.MouldCode = PFMS.MouldCode
        AND PFMM.[Status] = 9
        AND PFMM.MouldType = CASE @orderType 
            WHEN 'takeout' THEN 2 
            WHEN 'delivery' THEN 5 
            WHEN 'scaneDesk' THEN 6 
        END 
    -- 如果使用時段菜單，則關聯 P_FoodMould_M_Time 表進行時間篩選
    LEFT JOIN P_FoodMould_M_Time PFMT ON @useTimeBasedMenu = 1 
        AND PFMT.EnterpriseID = @enterpriseId 
        AND PFMT.MouldCode = PFMS.MouldCode
        AND (
            -- 檢查星期是否符合
            (@currentWeekDay = 2 AND PFMT.Week1 = 1) OR
            (@currentWeekDay = 3 AND PFMT.Week2 = 1) OR
            (@currentWeekDay = 4 AND PFMT.Week3 = 1) OR
            (@currentWeekDay = 5 AND PFMT.Week4 = 1) OR
            (@currentWeekDay = 6 AND PFMT.Week5 = 1) OR
            (@currentWeekDay = 7 AND PFMT.Week6 = 1) OR
            (@currentWeekDay = 1 AND PFMT.Week7 = 1)
        )
        AND (
            -- 檢查時間是否符合任一時間區段
            (@currentTime BETWEEN PFMT.BeginTime1 AND PFMT.EndTime1) OR
            (@currentTime BETWEEN PFMT.BeginTime2 AND PFMT.EndTime2) OR
            (@currentTime BETWEEN PFMT.BeginTime3 AND PFMT.EndTime3)
        )
    JOIN P_FoodMould PFM ON PFM.EnterpriseID = @enterpriseId AND PFM.MouldCode = PFMS.MouldCode
    JOIN P_Food PF ON PF.enterpriseID = @enterpriseId AND PF.Kind = PFM.Kind AND PF.ID = F.FoodId AND PF.NoKindAdd = '0'
    WHERE PFM.ID = F.FoodId 
  
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
                ISNULL(PFMJ.Stop,0) AS IsSoldOut,   
                FA2.Lock   
            FROM P_FoodAdd_Mould FA2  
            LEFT JOIN P_Data_Language_D LANGADD      
                ON LANGADD.EnterpriseID = @enterpriseid      
                AND LANGADD.SourceID = FA2.ID      
                AND LANGADD.TableName = 'FoodAdd'    
            LEFT JOIN P_FoodTasteAddMouldJoin PFMJ on PFMJ.EnterpriseID = @enterpriseId and PFMJ.TasteAddName = FA2.Name and PFMJ.ShopID = @shopId    
            WHERE FA2.AddKindID = FAK.ID      
            AND FA2.EnterpriseID = @enterpriseId      
            AND (FA2.Owner = F.FoodId OR FA2.[Owner] = F.FoodKind) 
            AND FA2.MouldCode = COALESCE(FMM.MouldCode, FMT.MouldCode)
            ORDER BY FA2.SN      
            FOR JSON PATH      
        ) AS Items,      
        FAK.needed AS MinSelectCount,    
        FAK.MaxCount AS MaxSelectCount    
    FROM @FoodIdsTable F    
    -- 透過 P_FoodMould_Shop、P_FoodMould_M 找出目標菜單的 MouldCode    
    JOIN P_FoodMould_Shop FMS ON FMS.EnterpriseID = @enterpriseId AND FMS.ShopID = @shopId    
    -- 關聯菜單主檔 - 根據是否使用時段菜單選擇不同的表
    LEFT JOIN P_FoodMould_M FMM ON @useTimeBasedMenu = 0
        AND FMM.EnterPriseID = @enterpriseId         
        AND FMM.MouldCode = FMS.MouldCode         
        AND FMM.[Status] = 9          
        AND FMM.MouldType = CASE @orderType          
            WHEN 'takeout' THEN 2
            WHEN 'homeDelivery' THEN 3          
            WHEN 'delivery' THEN 5           
            WHEN 'scaneDesk' THEN 6     
        END     
    -- 如果使用時段菜單，則關聯 P_FoodMould_M_Time 表進行時間篩選
    LEFT JOIN P_FoodMould_M_Time FMT ON @useTimeBasedMenu = 1 
        AND FMT.EnterpriseID = @enterpriseId 
        AND FMT.MouldCode = FMS.MouldCode
        AND (
            -- 檢查星期是否符合
            (@currentWeekDay = 2 AND FMT.Week1 = 1) OR
            (@currentWeekDay = 3 AND FMT.Week2 = 1) OR
            (@currentWeekDay = 4 AND FMT.Week3 = 1) OR
            (@currentWeekDay = 5 AND FMT.Week4 = 1) OR
            (@currentWeekDay = 6 AND FMT.Week5 = 1) OR
            (@currentWeekDay = 7 AND FMT.Week6 = 1) OR
            (@currentWeekDay = 1 AND FMT.Week7 = 1)
        )
        AND (
            -- 檢查時間是否符合任一時間區段
            (@currentTime BETWEEN FMT.BeginTime1 AND FMT.EndTime1) OR
            (@currentTime BETWEEN FMT.BeginTime2 AND FMT.EndTime2) OR
            (@currentTime BETWEEN FMT.BeginTime3 AND FMT.EndTime3)
        )
    JOIN P_FoodAdd_Mould FAM ON FAM.EnterpriseID = @enterpriseId AND FAM.MouldCode = COALESCE(FMM.MouldCode, FMT.MouldCode)    
    JOIN P_FoodAddKind FAK ON FAK.ID = FAM.AddKindID    
    -- 依據語系找出對應的顯示文字    
    LEFT JOIN P_Data_Language_D LANGKIND      
        ON LANGKIND.EnterpriseID = @enterpriseid      
        AND LANGKIND.SourceID = FAK.ID      
        AND LANGKIND.TableName = 'FoodAddKind'  
    WHERE (FAM.Owner = F.FoodId OR FAM.[Owner] = F.FoodKind)
    GROUP BY F.FoodId, F.FoodKind ,FAK.ID,FAK.SN, FAK.Name, FAK.MaxCount, FAK.needed, LANGKIND.Content, COALESCE(FMM.MouldCode, FMT.MouldCode)
    order by FAK.SN
END
GO
