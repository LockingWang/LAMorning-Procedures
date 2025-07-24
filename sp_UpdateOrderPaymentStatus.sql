CREATE   PROCEDURE [dbo].[sp_UpdateOrderPaymentStatus]  
    @EnterpriseId NVARCHAR(50),  
    @ShopId NVARCHAR(50),  
    @OrderId NVARCHAR(100),  
    @PlatformOrderId NVARCHAR(100),  
    @Status NVARCHAR(100),  
    @Action NVARCHAR(100),  
    @Amount DECIMAL(18, 2),  
    @TransactionDate NVARCHAR(100),  
    @errorCode INT OUTPUT,  
    @errorMessage NVARCHAR(MAX) OUTPUT  
AS  
  
BEGIN  
    SET NOCOUNT ON;  
  
    -- 宣告變數來儲存轉換後的 Action 值 
    DECLARE @ConvertedAction NVARCHAR(100); 
     
    -- 轉換 Action 值 
    SET @ConvertedAction = CASE @Action 
        WHEN 'SinopacWeb' THEN 'Sinopac' 
        WHEN 'LinePayWeb' THEN 'LINEpay_web' 
        WHEN 'JkoPayWeb' THEN 'JkoPay_web' 
        ELSE @Action 
    END; 
  
    BEGIN TRY  
        -- 參數驗證  
        IF @EnterpriseId IS NULL OR @ShopId IS NULL OR @OrderId IS NULL OR @PlatformOrderId IS NULL  
        BEGIN  
            SET @errorCode = 1;  
            SET @errorMessage = N'缺少必要參數：EnterpriseId、ShopId、OrderId 或 PlatformOrderId 不能為空';  
            RETURN;  
        END  
  
        -- 檢查 Status 是否為 success  
        IF @Status = 'success'  
        BEGIN  
            BEGIN TRANSACTION;  
  
            -- 更新 P_OrdersTemp_Web 表中的付款狀態  
            UPDATE P_OrdersTemp_Web  
            SET PayStatus = 1  
            WHERE ID = @OrderId;  
  
            SET @errorCode = 0;  
            SET @errorMessage = N'更新成功';  
  
            COMMIT TRANSACTION;  
        END  
        ELSE  
        BEGIN  
            SET @errorCode = 0;  
            SET @errorMessage = N'狀態不是 success，僅查詢訂單資訊';  
        END  
  
        -- 取得訂單資訊（無論 Status 為何都會執行）  
        SELECT * FROM P_OrdersTemp_Web WHERE ID = @OrderId;  
  
    END TRY  
    BEGIN CATCH  
        IF @@TRANCOUNT > 0  
            ROLLBACK TRANSACTION;  
  
        SET @errorCode = 1;  
        SET @errorMessage = N'更新訂單狀態時發生錯誤：' + ERROR_MESSAGE();  
    END CATCH  
END