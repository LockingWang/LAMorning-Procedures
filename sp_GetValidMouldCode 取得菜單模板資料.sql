SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_GetValidMouldCode]
    @enterpriseId NVARCHAR(50),
    @shopId NVARCHAR(50),
    @orderType NVARCHAR(50)
AS

-- 測試用
-- DECLARE 
-- @enterpriseId NVARCHAR(50) = 'xurf',
-- @shopId NVARCHAR(50) = 'A001',
-- @orderType NVARCHAR(50) = 'scaneDesk'

BEGIN
    SET NOCOUNT ON;

    DECLARE @useTimeBasedMenu BIT = 0;
    DECLARE @currentWeekDay INT = DATEPART(WEEKDAY, GETDATE());
    DECLARE @currentTime TIME = CAST(GETDATE() AS TIME);

    -- 判斷是否使用時段菜單
    SELECT @useTimeBasedMenu = CASE WHEN ParameterValue = 'true' THEN 1 ELSE 0 END
    FROM S_Parameter_Enterprise
    WHERE EnterpriseID = @enterpriseId
      AND ParameterGID = '79dabbec-a224-4f34-a13e-04540c9d548e';

    -- 先放進暫存表
    DECLARE @BaseMould TABLE (MouldCode NVARCHAR(50));
    INSERT INTO @BaseMould(MouldCode)
    SELECT fshop.MouldCode
    FROM P_FoodMould_Shop fshop
    WHERE fshop.EnterpriseID = @enterpriseId
      AND fshop.ShopID = @shopId;

    IF @useTimeBasedMenu = 0
    BEGIN
        SELECT DISTINCT fm.MouldCode
        FROM @BaseMould bm
        JOIN P_FoodMould_M fm
          ON fm.EnterpriseID = @enterpriseId
         AND fm.MouldCode = bm.MouldCode
         AND fm.[Status] = 9
         AND fm.MouldType = CASE @orderType
                               WHEN 'takeout' THEN 2
                               WHEN 'homeDelivery' THEN 3
                               WHEN 'delivery' THEN 5
                               WHEN 'scaneDesk' THEN 6
                             END;
    END
    ELSE
    BEGIN
        SELECT DISTINCT fmt.MouldCode
        FROM @BaseMould bm
        JOIN P_FoodMould_M_Time fmt
          ON fmt.EnterpriseID = @enterpriseId
         AND fmt.MouldCode = bm.MouldCode
         AND fmt.MouldType = CASE @orderType
                               WHEN 'takeout' THEN 2
                               WHEN 'homeDelivery' THEN 3
                               WHEN 'delivery' THEN 5
                               WHEN 'scaneDesk' THEN 6
                             END
         AND (
              (@currentWeekDay = 2 AND fmt.Week1 = 1) OR
              (@currentWeekDay = 3 AND fmt.Week2 = 1) OR
              (@currentWeekDay = 4 AND fmt.Week3 = 1) OR
              (@currentWeekDay = 5 AND fmt.Week4 = 1) OR
              (@currentWeekDay = 6 AND fmt.Week5 = 1) OR
              (@currentWeekDay = 7 AND fmt.Week6 = 1) OR
              (@currentWeekDay = 1 AND fmt.Week7 = 1)
             )
         AND (
              (@currentTime BETWEEN fmt.BeginTime1 AND fmt.EndTime1) OR
              (@currentTime BETWEEN fmt.BeginTime2 AND fmt.EndTime2) OR
              (@currentTime BETWEEN fmt.BeginTime3 AND fmt.EndTime3)
             );
    END
END
GO
