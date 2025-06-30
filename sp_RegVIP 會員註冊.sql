CREATE OR ALTER PROCEDURE [dbo].[sp_RegVIP]     
    @enterpriseId NVARCHAR(50),         -- 企業號 ID     
    @lineUId NVARCHAR(100),             -- LINE ID     
    @email NVARCHAR(50) = '',                -- 信箱     
    @phone NVARCHAR(50),                -- 電話     
    @name NVARCHAR(100),                -- 姓名     
    @sex INT = 1,                          -- 性別 1男 0女     
    @MT_NickName NVARCHAR(100),        -- LINE暱稱     
    --@password NVARCHAR(20) OUTPUT,      -- 隨機密碼 OUTPUT 回傳     
    @isFrom NVARCHAR(20) = 'LINElogin', -- 來源，預設 LINElogin     
    @MemberType NVARCHAR(10) = 'K',      -- 會員類型，預設 'K'     
	@errorCode INT OUTPUT,     
	@message NVARCHAR(MAX) OUTPUT     
AS     
BEGIN     
    SET NOCOUNT ON;     
     
    -- 檢查會員是否已存在   
    -- 檢查 VIP_CardInfo 表   
    IF EXISTS (   
        SELECT 1 FROM VIP_CardInfo    
        WHERE MemberNO = @phone    
        AND EnterPriseID = @enterpriseId   
    )   
    BEGIN   
        SET @errorCode = 1;   
        SET @message = N'會員已存在，VIP_CardInfo 表中有重複資料，電話號碼：' + @phone;   
        RETURN;   
    END   
   
    -- 檢查 VIP_Info 表   
    IF EXISTS (   
        SELECT 1 FROM VIP_Info    
        WHERE MemberNO = @phone    
        AND EnterPriseID = @enterpriseId   
    )   
    BEGIN   
        SET @errorCode = 1;   
        SET @message = N'會員已存在，VIP_Info 表中有重複資料，電話號碼：' + @phone;   
        RETURN;   
    END   
   
    -- 檢查 O_Members 表   
    IF EXISTS (   
        SELECT 1 FROM O_Members    
        WHERE Account = @phone    
        AND EnterpriseID = @enterpriseId   
    )   
    BEGIN   
        SET @errorCode = 1;   
        SET @message = N'會員已存在，O_Members 表中有重複資料，電話號碼：' + @phone;   
        RETURN;   
    END   
   
    BEGIN TRANSACTION    
        DECLARE @password NVARCHAR(20);    
        -- 產生六位數隨機密碼（英數混合）     
        SET @password = (     
            SELECT TOP 1 SUBSTRING(REPLACE(CONVERT(varchar(40), NEWID()), '-', ''), 1, 6)     
        );     
     
        -- 預先產生 GUID     
        DECLARE @vipCardInfoGID UNIQUEIDENTIFIER = NEWID();     
        DECLARE @vipInfoGID UNIQUEIDENTIFIER = NEWID();     
        DECLARE @memberGID UNIQUEIDENTIFIER = NEWID();     
        DECLARE @thirdGID UNIQUEIDENTIFIER = NEWID();     
        DECLARE @memberLevel NVARCHAR(50);    
        DECLARE @validDays INT;    
        DECLARE @validType INT;
        DECLARE @validDate DATETIME;
        SELECT @memberLevel=vct.CardTypeName,@validDays=vct.ValidDays,@validType=vct.ValidType,@validDate=vct.ExpiredDate FROM VIP_CardType vct     
            WHERE vct.EnterPriseID=@enterpriseId AND vct.CardTypeCode=@MemberType;    
        DECLARE @createDate DATETIME = (SELECT CAST(GETDATE() AS DATE));
        -- DECLARE @tradeRuleCode varchar(50) = (SELECT TradeRuleCode FROM VIP_TradeRules vtr WHERE vtr.EnterPriseID=@enterpriseId AND vtr.TradeTypeCode=1) 
        
        -- 根據 validType 決定過期日期
        DECLARE @expiredDate DATETIME;
        IF @validType = 1
            -- 1 = 售卡固定有效期天數，從今天開始加幾天後過期
            SET @expiredDate = DATEADD(DAY, @validDays, @createDate);
        ELSE IF @validType = 2
            -- 2 = 永久有效，固定過期日為 '9999-12-31 23:59:59.997'
            SET @expiredDate = '9999-12-31 23:59:59.997';
        ELSE IF @validType = 3
            -- 3 = 在固定期之前有效，有效期採用 @validDate
            SET @expiredDate = @validDate;
        ELSE
            -- 預設情況，使用原本的計算方式
            SET @expiredDate = DATEADD(DAY, @validDays, @createDate);
    
     
        -- 新增 VIP_CardInfo 資料     
        INSERT INTO VIP_CardInfo (GID,EnterPriseID,CardNO,CardID,MemberNO,CardTypeCode,SaleShopID,SaleDate,CardState,    
            ExpiredDate,BalanceLimit,Points,Bonus,Balance,TotalTrades,TotalSavings,TotalSales,    
	        [PassWord],PointsRedeemed,BonusRedeemed,Discount,Deposit,TotalCashSales,WeChatOpenID,CardKey,PayTotal,    
            PublicNum,PayExpiredDate,DifferenceCumulativeSales,UpgradeDate    
        )     
        VALUES (     
            @vipCardInfoGID,     
            @enterpriseId,     
            @phone, @phone, @phone,     
            @MemberType,    
            '9999',    
            @createDate,    
            2,    
            @expiredDate,    
            0.00,    
            0.00,    
            0.00,    
            0.00,    
            1,    
            0.00,    
            0.00,    
            @password,    
            0.00,    
            0.00,    
            0.00,    
            0.00,    
            0.00,    
            @phone,    
            '', -- CardKey 未知的六位數字串    
            0.00,    
            '', -- PublicNum    
            '2000-01-01 00:00:00.000',    
        0.00,    
            @createDate    
        );     
        IF @@ROWCOUNT <= 0    
		BEGIN     
           	SET @errorCode = 1;     
			SET @message = '會員電話' + @phone + ' 新增VIP_CardInfo失敗!';     
			ROLLBACK TRANSACTION;     
			RETURN;     
        END     
        Update VIP_CardInfo set Mac=SUBSTRING(sys.fn_sqlvarbasetostr(HASHBYTES('MD5',MemberNO+CardID+CardNO    
		    +CONVERT(varchar(10),CardState)    
		    +CONVERT(varchar(50),CardTypeCode)    
		    +CONVERT(varchar(10),ExpiredDate,112)    
		    +CONVERT(varchar(10),SaleDate,112)    
		    +CONVERT(varchar(50),SaleShopID)    
		    +CONVERT(varchar(14),Round(Balance,2))    
		    +CONVERT(varchar(14),Round(Points,2))    
		    +CONVERT(varchar(14),Round(Bonus,2))    
		    +CONVERT(varchar(10),TotalTrades)    
		    +CONVERT(varchar(14),Round(TotalSavings,2))    
		    +CONVERT(varchar(14),Round(TotalSales,2))    
		    +CONVERT(varchar(14),Round(PointsRedeemed,2))    
		    +CONVERT(VARCHAR(14),Round(BonusRedeemed,2)))),3,32)     
		where CardID=@phone and EnterPriseID=@EnterpriseID     
     
        -- 新增 VIP_Info 資料     
        INSERT INTO VIP_Info (     
            GID,     
            EnterPriseID,    
            MemberNO,     
            CardNO,    
            CardID,     
            MemberType,       
            CnName,     
            Mobile,    
            Addr,     
            Email,     
            UndertakeOrgCode,     
            Sex,     
          BirthType    
        )     
        VALUES (     
            @vipInfoGID,    
            @enterpriseId,      
            @phone,     
            @phone,     
            @phone,     
            @MemberType,     
            @name,     
            @phone,     
            '', --addr    
            '', --email    
            '9999', -- UndertakeOrgCode    
            case WHEN @sex=1 THEN '男' WHEN @sex=2 THEN '女' ELSE '保密' END,     
            1    
        );     
        IF @@ROWCOUNT <= 0    
		BEGIN     
           	SET @errorCode = 2;     
			SET @message = '會員電話' + @phone + ' 新增VIP_Info失敗!';     
			ROLLBACK TRANSACTION;     
			RETURN;     
        END     
     
        -- 新增 O_Members 資料     
        INSERT INTO O_Members (     
            GID,     
            EnterpriseID,    
            isFrom,      
            Account,     
            Password,    
            Type,     
            Name,     
            Sex,     
            Birthday,     
            Members_Level,     
            Email,     
            City,     
            Town,     
            Code,     
            Address,     
            PrePhone,     
            Phone,     
            Pass,     
            VIP,     
            Epaper_Order,     
            IsDisable,    
            CreateDate,      
            CreateUser,     
            UpdateUser,     
            LastModify,     
            LastOP,    
            LastState,     
            EDM_Order,     
            EDMDate    
        )     
        VALUES (     
            @memberGID,     
            @enterpriseId,    
            @isFrom,      
            @phone,     
            @password,     
            1,     
            @name,     
            @sex,     
            '1900-01-01 00:00:00.000',     
            @memberLevel,     
            @email,     
            '',     
            '',     
            '',     
            '',     
            '886',    
            @phone,     
            1,     
            1,     
            1,     
            0,     
            @createDate,     
            @phone,    
            @createDate,     
            @createDate,    
            @phone,     
            'A',     
            1,     
            @createDate     
        );     
        IF @@ROWCOUNT <= 0    
		BEGIN     
           	SET @errorCode = 3;     
			SET @message = '會員電話' + @phone + ' 新增O_Members失敗!';     
			ROLLBACK TRANSACTION;     
			RETURN;     
        END     
     
        -- 新增 O_MembersThird 資料     
        INSERT INTO O_MembersThird (     
            GID,     
            EnterpriseID,     
            isFrom,     
            MB_GID,     
            MT_ID,     
            MT_Email,     
            MT_NickName,     
            CreateDate,    
            CreateUser,     
            LastModify,     
            LastOP,     
            LastState    
        )     
        VALUES (     
            @thirdGID,     
            @enterpriseId,     
            @isFrom,     
            @memberGID,     
            @lineUId,     
            @email,     
            @MT_NickName,     
            @createDate,     
            @phone,    
            @createDate,     
    @phone,     
            'A'    
        );     
        IF @@ROWCOUNT <= 0    
		BEGIN     
           	SET @errorCode = 4;     
			SET @message = '會員電話' + @phone + ' 新增O_MembersThird失敗!';     
			ROLLBACK TRANSACTION;     
			RETURN;     
        END     
  
        --新增註冊交易紀錄  
        --insert INTO VIP_Trade (GID,EnterPriseID,TradeNum,MemberNo,CardNO,CardID,OrderID,OrderNO,CheckID,ItemID,ShopID,MachineID,WorkDate,CardTypeCode,CardState,Discount,Deposit,ValidDays,ExpiredDate,SaleDate,SaleShopID,TradeTypeCode,TradeTime,  
            --TotalTrades,TradeAmount,TradePoints,TradeBonus,Balance,Points,Bonus,TotalSavings,TotalCashSales,TotalSales,PointsRedeemed,BonusRedeemed,TotalInvoiceAmount,HostName,LastModify,Remarks,TradeRuleCode,OldTradeNum,BackTradeNum,  
            --PointMoneyRate,PointMoney,FoodID,FoodKindID,PresentMoney,PayTotal,TradePayTotal,PayType,PayExpiredDate,PointExpiredDate)  
        --SELECT NEWID(),@enterpriseId,NEWID(),@phone,@phone,@phone,'','','','','9999','A',convert(varchar,GETDATE(),112),@MemberType,2,0,0.00,@validDays,@expiredDate,@createDate,'9999',  
        --    1,@createDate,1,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,'',@createDate,'',@tradeRuleCode,'','',0.00,0.00,'','',0.00,0.00,0.00,'','2000-01-01 00:00:00.000','2000-01-01 00:00:00.000'  
  --      IF @@ROWCOUNT <= 0    
		--BEGIN     
  --         	SET @errorCode = 4;     
		--	SET @message = '會員電話' + @phone + ' 新增VIP_Trade失敗!';     
		--	ROLLBACK TRANSACTION;     
		--	RETURN;     
  --      END    
  
            
        SET @errorCode = 0;    
        SET @message = N'會員註冊成功，電話號碼：' + @phone;   
    COMMIT TRANSACTION;    
END; 