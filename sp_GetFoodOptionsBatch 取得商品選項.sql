CREATE   PROCEDURE [dbo].[sp_GetFoodOptionsBatch]     
    @enterpriseId NVARCHAR(50),     
    @shopId NVARCHAR(50),     
    @foodIds NVARCHAR(MAX),     
    @orderType NVARCHAR(50),     
    @langId NVARCHAR(50)     
AS     
    
 
--DECLARE     
    --@enterpriseId NVARCHAR(50) = 'XFlamorning',      
    --@shopId NVARCHAR(50) = '082B03',    
    --@foodIds NVARCHAR(MAX) = 'A5648910,A1147643,A1547621,A1547622,A1547623,A1547624,A1547625,A1547626,A1547627,A1547628,A1547629,A1547630,A1547631,A1547632,A1547633,A1547634,A1548870,A1547635,A2447668,A2447667,A2447664,A2447666,A2447665,A2547656,A254765
-- 8,A2547655,A2547657,A2547659,A2547653,A2547654,A2647660,A2647661,A2747662,A2747663,A0147682,A0147688,A0147692,A0147687,A0147690,A0147681,A0147685,A0147684,A0147683,A0147686,A0147693,A0147691,A0147694,A0147697,A0147696,A0147695,A0147698,A0247679,A0247669,A
-- 0247671,A0247670,A0247678,A0247673,A0247674,A0247672,A0247675,A0247676,A0247677,A0247680,A0347702,A0347700,A0347703,A0347712,A0347714,A0347699,A0347701,A0347704,A0347705,A0347707,A0347706,A0347709,A0347708,A0347710,A0347711,A0347713,A0448808,A0448805,A044
-- 8806,A0448807,A0448809,A0448810,A0548840,A0548838,A0548839,A0548841,A0548842,A0648843,A0648844,A0648847,A0648845,A0648846,A0648848,A0748817,A0748816,A0748832,A0748833,A0748836,A0748837,A0948881,A0948883,A0948880,A0948884,A0948882,A0948885,A1048872,A104887
1,A1048873,A1248890,A1248892,A1248891,A1348886,A1348888,A1348887,A1348889,A1448849,A1448850,A1448851,A1448852,A1448853,A1448854,A1448856,A1448855,A1448857,A1448858,A1448866,A1448867,A1448868,A1448869',    
    --@orderType NVARCHAR(50) = 'takeout',   
    --@langId NVARCHAR(50) = 'TW'      
    
    
BEGIN     
    SET NOCOUNT ON;     
         
    -- 將逗號分隔的 foodIds 轉換為表格     
    DECLARE @FoodIdsTable TABLE (FoodId NVARCHAR(50))     
    INSERT INTO @FoodIdsTable     
    SELECT value FROM STRING_SPLIT(@foodIds, ',')     
    -- 加上類別 
    insert into @FoodIdsTable 
    select DISTINCT PFM.Kind from P_FoodMould_M PFMM  
    join P_FoodMould_Shop PFMS on PFMM.EnterpriseID=PFMS.EnterpriseID and PFMM.MouldCode=PFMS.MouldCode 
    join P_FoodMould PFM on PFMM.EnterpriseID=PFM.EnterpriseID and PFMM.MouldCode=PFM.MouldCode 
    where PFM.EnterpriseID=@enterpriseId and PFMS.ShopID = @shopId and PFM.ID in (select FoodID from @FoodIdsTable)  
    and PFMM.MouldType=CASE @orderType         
            WHEN 'takeout' THEN 2         
            WHEN 'delivery' THEN 5          
            WHEN 'scaneDesk' THEN 6    
        END   
    and PFMM.[Status] = 9 
 
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
    JOIN P_FoodAdd_Mould FAM ON FAM.EnterpriseID = @enterpriseId AND FAM.MouldCode = FMM.MouldCode   
    JOIN P_FoodAddKind FAK ON FAK.ID = FAM.AddKindID   
    -- 依據語系找出對應的顯示文字   
    LEFT JOIN P_Data_Language_D LANGKIND     
        ON LANGKIND.EnterpriseID = @enterpriseid     
        AND LANGKIND.SourceID = FAK.ID     
        AND LANGKIND.TableName = 'FoodAddKind' 
    WHERE FAM.Owner = F.FoodId 
    GROUP BY F.FoodId, FAK.ID, FAK.Name, FAK.MaxCount, FAK.needed, LANGKIND.Content, FMM.MouldCode   
END