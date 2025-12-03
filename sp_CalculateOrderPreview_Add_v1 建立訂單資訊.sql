SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[sp_CalculateOrderPreview_Add_v1]       
	@EnterpriseID VARCHAR(50),       
	@ShopID VARCHAR(100),      
	@MemberNo VARCHAR(100),    
	@MemberName VARCHAR(100),    
	@Operator VARCHAR(100),      
	@OrderJson NVARCHAR(MAX),      
	@ItemsJson NVARCHAR(MAX),       
	@CouponsJson NVARCHAR(MAX),  
	@errorCode INT OUTPUT,      
	@message NVARCHAR(MAX) OUTPUT      
AS      
BEGIN      
	SET NOCOUNT ON;       
      
	BEGIN TRY      
		BEGIN TRANSACTION      
      
			DECLARE @OrderID VARCHAR(100) = (SELECT JSON_VALUE(@OrderJson, '$.ID'));      
			DECLARE @SerialType VARCHAR(40) = (SELECT JSON_VALUE(@OrderJson, '$.SaleType'));      
			DECLARE @PreOrderNo varchar(100), @SerialNum VARCHAR(5),@SerialDate DATE;      
			DECLARE @now DATETIME = GETDATE();  
      
			IF @OrderID IS NULL      
			BEGIN      
            	SET @errorCode = 1;      
				SET @message = 'OrderID錯誤!';      
				ROLLBACK TRANSACTION;      
				RETURN;      
            END      
      
			IF @OrderJson IS NULL      
			BEGIN      
               	SET @errorCode = 1;      
				SET @message = '訂單資訊不得為空!';      
				ROLLBACK TRANSACTION;      
				RETURN;      
            END      
			IF @ItemsJson is NULL      
			BEGIN      
               	SET @errorCode = 1;      
				SET @message = '訂單品項不得為空!';      
				ROLLBACK TRANSACTION;      
				RETURN;      
            END      
      
			IF @Operator is NULL      
			SET @Operator = '';      
			      
			SELECT @SerialDate = cast(@now AS DATE);      
			SET @SerialType = 'Online_' + @SerialType;      
			      
            -- [優化] 先設定暫時的流水號
            SET @SerialNum = '00000';

			-- [方案A] 移除 OUTPUT INSERTED.*
			INSERT INTO P_OrdersTemp_Web (EnterpriseID,ShopID,OPERATOR,OrderStatus,OrderNo2,LastModify,ID,DeskID,Machine,VendNo,SaleTime,Man,Woman,Child,Baby,      
				Total,PayTotal,ServicePercent,ServiceTotal,TendTotal,InvoiceTotal,VIPNo,VIPName,SaleType,MeTime,VIPTel,AgioDiscount,AgioCost,AgioPercent,CardID,WechatOpenID,OrderFoodCount,PayStatus,      
				VipAddr,OrderType,AppFunGID,ReceiverName,ReceiverMark,TakeWayTime,firmServiceFee,deliverFee,      
				packageFee,activityShopPart,activityTotal,activityFirmPart,PayChannel,BillType,TakeWayTime2,      
				ReceiptOP,TakeWayOP2,CarrierId,PrintStatus,VipAddrHead,DonateCode,SubmitTimes)      
			select @EnterpriseID,@ShopID,@Operator,0,@EnterpriseID + MeTime + @SerialNum,@now,ID,DeskID,Machine,VendNo,SaleTime,Man,Woman,Child,Baby,      
				Total,PayTotal,ServicePercent,ServiceTotal,TendTotal,InvoiceTotal,VIPNo,VIPName,SaleType,      
				MeTime,VIPTel,AgioDiscount,AgioCost,AgioPercent,CardID,WechatOpenID,OrderFoodCount,PayStatus,      
				VipAddr,OrderType,AppFunGID,ReceiverName,ReceiverMark,TakeWayTime,firmServiceFee,deliverFee,      
				packageFee,activityShopPart,activityTotal,activityFirmPart,    
				CASE WHEN PayChannel = 'JkoPayWeb' THEN 'JkoPay_web' ELSE PayChannel END,      
				BillType,TakeWayTime2,      
				ReceiptOP,TakeWayOP2,CarrierId,PrintStatus,VipAddrHead,DonateCode,1 FROM OPENJSON(@OrderJson)      
			WITH (ID varchar(100), DeskID varchar(100), Machine varchar(24), VendNo varchar(40), SaleTime datetime, Man int, Woman int, Child int, Baby int,      
				Total float, PayTotal float, ServicePercent float, ServiceTotal float, TendTotal float, InvoiceTotal float, VIPNo varchar(100), VIPName nvarchar(100), SaleType varchar(40),      
				MeTime varchar(100), VIPTel varchar(100), AgioDiscount decimal, AgioCost decimal, AgioPercent decimal, CardID varchar(100), WechatOpenID varchar(100), OrderFoodCount decimal, PayStatus int,      
				VipAddr varchar(200), OrderType int, AppFunGID varchar(100), ReceiverName nvarchar(100), ReceiverMark varchar(500), TakeWayTime datetime,      
				firmServiceFee decimal, deliverFee decimal, packageFee decimal, activityShopPart decimal, activityTotal decimal, activityFirmPart decimal,      
				PayChannel varchar(20), BillType varchar(20), TakeWayTime2 datetime, ReceiptOP varchar(100), TakeWayOP2 varchar(100), CarrierId varchar(100), PrintStatus int, VipAddrHead nvarchar(100), DonateCode nvarchar(10));      
      
			-- [方案A] 移除 OUTPUT INSERTED.*
			INSERT INTO P_ItemsTemp_Web (EnterpriseID,OrderID,Operator,SHOPID,LastModify,ID,FoodID,MainID,KindID,Parent,[Add],[Count],Price,Addcost,Total,FoodName,      
				Taste,InputTime,ServCost,Discount,TotalDiscount,Special,Special1,Memo,ChangePrice,BatchID,OrderIndex)      
			SELECT @EnterpriseID,@OrderID,@Operator,@ShopID,@now,ID,FoodID,MainID,KindID,Parent,[Add],[Count],Price,AddCost,Total,FoodName,      
				ISNULL(Taste, '') AS Taste,InputTime,ServCost,Discount,TotalDiscount,Special,Special1,ISNULL(Memo, '') AS Memo,ChangePrice,BatchID,1 * 10000 + OrderIndex      
			FROM OPENJSON(@ItemsJson)      
			WITH (ID VARCHAR(100), FoodID VARCHAR(100), MainID VARCHAR(100), KindID VARCHAR(100), Parent VARCHAR(100), [Add] VARCHAR(300), [Count] FLOAT, Price FLOAT, AddCost FLOAT, Total FLOAT, FoodName VARCHAR(200),      
				Taste VARCHAR(300), InputTime DATETIME, ServCost BIT, Discount BIT, TotalDiscount BIT, Special VARCHAR(100), Special1 VARCHAR(100), Memo VARCHAR(100), ChangePrice BIT, BatchID VARCHAR(100), OrderIndex INT);      
  
			-- [方案A] INSERT 優惠券資料（含 ItemName）
IF @CouponsJson IS NOT NULL  
BEGIN  
	INSERT INTO P_AgioTemp_Web (
		EnterpriseID,
        ShopID,
        OrderID,
        WorkDate,
        WorkTime,
        LastModify,
        ID,
        ItemID,
        [Owner],
        AgioReason,
        AgioPercent,
        AgioTotal,
        AgioCost,
        ReasonID,
        ReasonName,
        AgioType,
        ItemName        -- ★ 新增欄位
    )
	SELECT
        @EnterpriseID,
        @ShopID,
        @OrderID,
        CONVERT(varchar,@now,112),
        REPLACE(CONVERT(VARCHAR(8), @now, 108), ':', ''),
        @now,
        ID,
        ItemID,
        [Owner],
        AgioReason,
        AgioPercent,
        AgioTotal,
        AgioCost,
        ReasonID,
        ReasonName,
        AgioType,
        ItemName        -- ★ 新增欄位
	FROM OPENJSON(@CouponsJson)      
	WITH (
        ID VARCHAR(100),
        ItemID VARCHAR(100),
        [Owner] VARCHAR(50),
        AgioReason NVARCHAR(100),
        AgioPercent FLOAT,
        AgioTotal FLOAT,
        AgioCost FLOAT,
        ReasonID VARCHAR(40),
        ReasonName NVARCHAR(100),
        AgioType VARCHAR(50),
        ItemName NVARCHAR(400)        -- ★ 新增欄位
    );
END


            -- [優化] 交易尾端：執行取號並更新訂單
            BEGIN TRY      
				EXEC dbo.xs_GetNextSerialNumber_v1 @EnterpriseID,@ShopID,@SerialDate,@SerialType,@SerialNum OUTPUT;      
			END TRY      
			BEGIN CATCH      
				IF ERROR_NUMBER() = 1205
				BEGIN       
					THROW 50001, '獲取流水號時系統繁忙，請稍後再試。', 1;      
				END	      
				ELSE   
				BEGIN       
					THROW;      
				END	      
			END CATCH; 

            -- [優化] 更新 OrderNo2 (填入正確的流水號)
            DECLARE @MeTime VARCHAR(100);
            SELECT @MeTime = MeTime FROM P_OrdersTemp_Web WHERE ID = @OrderID AND EnterpriseID = @EnterpriseID;

            UPDATE P_OrdersTemp_Web
            SET OrderNo2 = @EnterpriseID + @MeTime + @SerialNum
            WHERE ID = @OrderID AND EnterpriseID = @EnterpriseID;

			-- [方案A] 在 COMMIT 前返回結果集（保證返回正確的 OrderNo2）
			SELECT * FROM P_OrdersTemp_Web 
			WHERE ID = @OrderID AND EnterpriseID = @EnterpriseID;

			SELECT * FROM P_ItemsTemp_Web 
			WHERE OrderID = @OrderID AND EnterpriseID = @EnterpriseID
			ORDER BY OrderIndex;

			-- 處理優惠券結果集（可能為空）
			IF @CouponsJson IS NOT NULL
			BEGIN
				SELECT * FROM P_AgioTemp_Web 
				WHERE OrderID = @OrderID AND EnterpriseID = @EnterpriseID;
			END
			ELSE
			BEGIN
				-- 回傳空結果集（保持與原版一致）
				SELECT EnterpriseID,ShopID,ID,OrderID,WorkDate,WorkTime,LastModify,ItemID,[Owner],AgioReason,AgioPercent,AgioTotal,AgioCost,ReasonID,ReasonName,AgioType 
				FROM P_AgioTemp_Web WHERE 1=2;
			END
  
			SET @errorCode = 0;      
			SET @message = '新增成功!';      
		COMMIT TRANSACTION;
	END TRY      
	BEGIN CATCH      
		IF XACT_STATE() <> 0      
			ROLLBACK TRANSACTION;      
		THROW;
	END CATCH;
END

GO
