CREATE PROCEDURE [dbo].[sp_CheckOrderExpire]
    @EnterpriseID NVARCHAR(50),
    @ShopID NVARCHAR(50),
    @OrderID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- 主查詢
    SELECT 
        ISNULL(
            CASE 
                WHEN DATEADD(
                         SECOND, 
                         TRY_CAST(ISNULL(shop.[Value], D.DefaultValue) AS INT), 
                         o.LastModify
                     ) > GETDATE() 
                THEN 1 
                ELSE 0 
            END,
            1  -- 發生例外或查不到資料 → 一律通過
        ) AS IsPass
    FROM P_OrdersTemp_Web o
    LEFT JOIN S_AppSetting_Shop shop 
        ON shop.EnterpriseID = o.EnterpriseID 
       AND shop.ShopID = o.ShopID
       AND shop.AppSetting_D_GID = (
            SELECT TOP 1 D2.GID 
            FROM S_AppSetting_M M2
            JOIN S_AppSetting_D D2 
                ON D2.AppSetting_M_GID = M2.GID 
               AND D2.Name = 'orderIntervalSeconds'
            WHERE M2.ModeID = 'scaneDesk'
       )
    LEFT JOIN S_AppSetting_M M ON M.ModeID = 'scaneDesk'
    LEFT JOIN S_AppSetting_D D 
        ON D.AppSetting_M_GID = M.GID 
       AND D.Name = 'orderIntervalSeconds'
    WHERE o.EnterpriseID = @EnterpriseID
      AND o.ShopID = @ShopID
      AND o.ID = @OrderID

    UNION ALL

    -- 如果找不到訂單，仍回傳一列 IsPass = 1
    SELECT 1 AS IsPass
    WHERE NOT EXISTS (
        SELECT 1
        FROM P_OrdersTemp_Web
        WHERE EnterpriseID = @EnterpriseID
          AND ShopID = @ShopID
          AND ID = @OrderID
    );
END
GO
