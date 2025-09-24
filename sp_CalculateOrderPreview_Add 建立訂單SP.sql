CREATE   PROCEDURE [dbo].[sp_CalculateOrderPreview_Add]       
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
			      
			BEGIN TRY      
				EXEC dbo.xs_GetNextSerialNumber @EnterpriseID,@ShopID,@SerialDate,@SerialType,@SerialNum OUTPUT;      
			END TRY      
			BEGIN CATCH      
				IF ERROR_NUMBER() = 1205 -- 鎖等待超時錯誤      
				BEGIN       
					THROW 50001, '獲取流水號時系統繁忙，請稍後再試。', 1;      
				END	      
				ELSE       
				BEGIN       
					THROW;      
				END	      
			END CATCH      
			      
			INSERT INTO P_OrdersTemp_Web (EnterpriseID,ShopID,OPERATOR,OrderStatus,OrderNo2,LastModify,ID,DeskID,Machine,VendNo,SaleTime,Man,Woman,Child,Baby,      
				Total,PayTotal,ServicePercent,ServiceTotal,TendTotal,InvoiceTotal,VIPNo,VIPName,SaleType,--LastModify,      
				MeTime,VIPTel,AgioDiscount,AgioCost,AgioPercent,CardID,WechatOpenID,OrderFoodCount,PayStatus,      
				VipAddr,OrderType,AppFunGID,ReceiverName,ReceiverMark,TakeWayTime/*,ReceiptTime*/,firmServiceFee,deliverFee,      
				packageFee,activityShopPart,activityTotal,activityFirmPart,PayChannel,BillType,TakeWayTime2,      
				ReceiptOP,TakeWayOP2,CarrierId,PrintStatus,VipAddrHead,DonateCode,SubmitTimes)      
			OUTPUT INSERTED.*      
			select @EnterpriseID,@ShopID,@Operator,0,@EnterpriseID + MeTime + @SerialNum,@now,ID,DeskID,Machine,VendNo,SaleTime,Man,Woman,Child,Baby,      
				Total,PayTotal,ServicePercent,ServiceTotal,TendTotal,InvoiceTotal,@MemberNo,@MemberName,SaleType,      
				MeTime,VIPTel,AgioDiscount,AgioCost,AgioPercent,CardID,WechatOpenID,OrderFoodCount,PayStatus,      
				VipAddr,OrderType,AppFunGID,ReceiverName,ReceiverMark,TakeWayTime,firmServiceFee,deliverFee,      
				packageFee,activityShopPart,activityTotal,activityFirmPart,    
				CASE WHEN PayChannel = 'JkoPayWeb' THEN 'JkoPay_web' ELSE PayChannel END,      
				BillType,TakeWayTime2,      
				ReceiptOP,TakeWayOP2,CarrierId,PrintStatus,VipAddrHead,DonateCode,1 FROM OPENJSON(@OrderJson)      
			WITH (      
				ID varchar (100) ,      
				DeskID varchar (100) ,      
				Machine varchar (24) ,      
				VendNo varchar(40),      
				SaleTime datetime  ,      
				Man int  ,      
				Woman int  ,      
				Child int  ,      
				Baby int  ,      
				Total float  ,      
				PayTotal float  ,      
				ServicePercent float  ,      
				ServiceTotal float  ,      
				TendTotal float  ,      
				InvoiceTotal float  ,      
				--VIPNo varchar (100) ,      
				--VIPName nvarchar (100) ,      
				SaleType varchar (40) ,      
				--LastModify datetime  ,      
				MeTime varchar (100) ,      
				VIPTel varchar (100) ,      
				AgioDiscount decimal  ,      
				AgioCost decimal  ,      
				AgioPercent decimal  ,      
				CardID varchar (100) ,      
				--OrderStatus int  ,   
				WechatOpenID varchar (100) ,      
				OrderFoodCount decimal  ,      
				PayStatus int  ,      
				VipAddr varchar (200) ,      
				OrderType int  ,      
				AppFunGID varchar (100) ,      
				ReceiverName nvarchar (100) ,      
				ReceiverMark varchar(100),      
				TakeWayTime datetime  ,      
				--ReceiptTime datetime  ,      
				firmServiceFee decimal  ,      
				deliverFee decimal  ,      
				packageFee decimal  ,      
				activityShopPart decimal  ,      
				activityTotal decimal  ,      
				activityFirmPart decimal  ,      
				PayChannel varchar (20) ,      
				BillType varchar (20) ,      
				TakeWayTime2 datetime  ,      
				ReceiptOP varchar (100) ,      
				TakeWayOP2 varchar (100) ,      
				CarrierId varchar (100) ,      
				PrintStatus int  ,      
				VipAddrHead nvarchar (100),      
				DonateCode nvarchar(10)      
			);      
      
			INSERT INTO P_ItemsTemp_Web (EnterpriseID,OrderID,Operator,SHOPID,LastModify,ID,FoodID,MainID,KindID,Parent,[Add],[Count],Price,Addcost,Total,FoodName,      
				Taste,InputTime,ServCost,Discount,TotalDiscount,Special,Special1,Memo/*,LastModify*/,ChangePrice,BatchID,OrderIndex)      
			OUTPUT INSERTED.*      
			SELECT @EnterpriseID,@OrderID,@Operator,@ShopID,@now,ID,FoodID,MainID,KindID,Parent,[Add],[Count],Price,AddCost,Total,FoodName,      
				ISNULL(Taste, '') AS Taste,InputTime,ServCost,Discount,TotalDiscount,Special,Special1,ISNULL(Memo, '') AS Memo,ChangePrice,BatchID,1 * 10000 + OrderIndex      
			FROM OPENJSON(@ItemsJson)      
			WITH (      
				ID VARCHAR(100),       
				FoodID VARCHAR(100),      
				MainID VARCHAR(100),      
				KindID VARCHAR(100),      
				Parent VARCHAR(100),      
				[Add] VARCHAR(300),      
				[Count] FLOAT,      
				Price FLOAT,      
				AddCost FLOAT,      
				Total FLOAT,      
				FoodName VARCHAR(200),      
				Taste VARCHAR(300),      
				InputTime DATETIME,      
				ServCost BIT,      
				Discount BIT,      
				TotalDiscount BIT,      
				Special VARCHAR(100),      
				Special1 VARCHAR(100),      
				Memo VARCHAR(100),      
				--LastModify DATETIME,      
				ChangePrice BIT,      
				BatchID VARCHAR(100),      
				OrderIndex INT      
			);      
  
			-- Coupons  
			IF @CouponsJson IS NOT NULL  
			BEGIN  
				INSERT INTO P_AgioTemp_Web (EnterpriseID,ShopID,OrderID,WorkDate,WorkTime,LastModify,ID,ItemID,[Owner],AgioReason,AgioPercent,AgioTotal,AgioCost,ReasonID,ReasonName,AgioType)  
				OUTPUT INSERTED.*    
				SELECT @EnterpriseID,@ShopID,@OrderID,CONVERT(varchar,@now,112),REPLACE(CONVERT(VARCHAR(8), @now, 108), ':', ''),@now,* FROM OPENJSON(@CouponsJson)      
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
					AgioType VARCHAR(50)  
				);      
			END  
			ELSE   
			BEGIN  
				--回傳空陣列  
				SELECT EnterpriseID,ShopID,ID,OrderID,WorkDate,WorkTime,LastModify,ItemID,[Owner],AgioReason,AgioPercent,AgioTotal,AgioCost,ReasonID,ReasonName,AgioType FROM P_AgioTemp_Web WHERE 1=2  
			END  
  
			SET @errorCode = 0;      
			SET @message = '新增成功!';      
		COMMIT TRANSACTION      
	END TRY      
	BEGIN CATCH      
		IF XACT_STATE() <> 0      
			ROLLBACK TRANSACTION;      
		THROW      
	END CATCH      
END 