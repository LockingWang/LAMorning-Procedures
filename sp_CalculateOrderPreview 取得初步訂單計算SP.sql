SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_CalculateOrderPreview] 
    @enterpriseId NVARCHAR(50),         -- 企業號
    @shopId NVARCHAR(50),               -- 門市 
    @memberNo NVARCHAR(50) = NULL,      -- 會員編號
    @memberName NVARCHAR(50) = NULL,    -- 會員名稱
	@order NVARCHAR(MAX),               -- 訂單資訊 (JSON格式) 
    @items NVARCHAR(MAX),               -- 餐點清單 (JSON格式) 
    @orderCoupons NVARCHAR(MAX) = NULL, -- 整單優惠券清單 (JSON格式)  
	@operator varchar(100), 
	@errorCode INT OUTPUT, 
	@message NVARCHAR(MAX) OUTPUT 
AS 
BEGIN 
    SET NOCOUNT ON; 
     
	BEGIN TRY 
		DECLARE @OrderID VARCHAR(100) = (SELECT JSON_VALUE(@order, '$.ID')); 
		IF @OrderID IS NULL 
		BEGIN 
           	SET @errorCode = 1; 
			SET @message = 'OrderID錯誤!'; 
			RETURN; 
        END 
 
		IF NOT EXISTS (SELECT 1 FROM P_OrdersTemp_Web WHERE EnterpriseID=@enterpriseId AND ID=@OrderID) 
		BEGIN 
			EXEC sp_CalculateOrderPreview_Add 
				@EnterpriseID = @enterpriseId,
				@ShopID = @shopId,
				@MemberNo = @memberNo,
				@MemberName = @memberName,
				@Operator = @operator,
				@OrderJson = @order,
				@ItemsJson = @items,
                @CouponsJson = @orderCoupons,
				@errorCode = @errorCode OUTPUT,
				@message = @message OUTPUT;
        END 
		ELSE  
		BEGIN  
           	SET @errorCode = 1; 
			SET @message = '訂單已存在!'; 
			RETURN; 
		END	 
	END TRY 
	BEGIN CATCH 
		SET @errorCode = 1; 
		SET @message = N'計算訂單出現意外錯誤!'; 
		SET @message += ': ' + ERROR_MESSAGE(); 
	END CATCH 
END
GO
