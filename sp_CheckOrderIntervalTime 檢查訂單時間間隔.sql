CREATE PROCEDURE [dbo].[sp_CheckOrderIntervalTime]
    @EnterpriseID NVARCHAR(50),
    @ShopID NVARCHAR(50),
    @OrderID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- 取得訂單與冷卻秒數
    SELECT 
        o.ID AS OrderID,
        o.LastModify,
        ISNULL(shop.[Value], D.DefaultValue) AS IntervalSeconds,
        DATEADD(SECOND, TRY_CAST(ISNULL(shop.[Value], D.DefaultValue) AS INT), o.LastModify) AS CooldownEndTime,
        CASE 
            WHEN o.ID IS NULL OR DATEADD(SECOND, TRY_CAST(ISNULL(shop.[Value], D.DefaultValue) AS INT), o.LastModify) <= GETDATE()
            THEN 1  -- 可以下單（找不到訂單也視為可以下單）
            ELSE 0  -- 冷卻中
        END AS IsPass,
        CASE 
            WHEN shop.[Value] IS NOT NULL THEN 'ShopSetting'
            ELSE 'DefaultSetting'
        END AS SettingType
    FROM P_OrdersTemp_Web o
    LEFT JOIN S_AppSetting_Shop shop 
        ON shop.EnterpriseID = @EnterpriseID
       AND shop.ShopID = @ShopID
       AND shop.AppSetting_D_GID = (
            SELECT TOP 1 D2.GID 
            FROM S_AppSetting_M M2
            JOIN S_AppSetting_D D2 
                ON D2.AppSetting_M_GID = M2.GID 
               AND D2.Name = 'orderIntervalSeconds'
            WHERE M2.ModeID = 'scaneDesk'
       )
    LEFT JOIN S_AppSetting_M M 
        ON M.ModeID = 'scaneDesk'
    LEFT JOIN S_AppSetting_D D 
        ON D.AppSetting_M_GID = M.GID 
       AND D.Name = 'orderIntervalSeconds'
    WHERE o.ID = @OrderID;
END
GO
