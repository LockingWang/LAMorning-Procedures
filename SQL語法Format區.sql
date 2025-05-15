SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @enterpriseid VARCHAR(50),
            @pro_code VARCHAR(50),
            @statustime DATETIME;

    SET @enterpriseid = :EnterpriseID;
    SET @pro_code = ':pro_code';
    SET @statustime = GETDATE();

    -- 先鎖住
    UPDATE VIP_ProMotion
    SET status = 2,
        StatusPersonal = :UserCode,
        StatusTime = @statustime
    WHERE Pro_Code = @pro_code
      AND EnterPriseID = @enterpriseid;

    DECLARE @tcount INT,
            @time1 DATETIME,
            @time2 DATETIME,
            @cardtradenum VARCHAR(50),
            @ticketinfoid VARCHAR(50),
            @tradenum VARCHAR(50);

    SET @time1 = GETDATE();
    SET @cardtradenum = NEWID();

    DECLARE @MemberNO VARCHAR(50),
            @CardID VARCHAR(50),
            @CardNO VARCHAR(50),
            @TicketTypeCode VARCHAR(50),
            @PresentTicketCount INT,
            @ShopID VARCHAR(100),
            @TicketPrice INT,
            @ExpiredDate VARCHAR(10),
            @TicketDiscount DECIMAL(14,2);

    DECLARE cursor0 CURSOR FOR
    SELECT b.MemberNO, e.CardID, e.CardNO,
           c.TicketTypeCode, PresentTicketCount, a.ShopID, d.TicketPrice,
           CASE
               WHEN ValidType = 1 THEN CONVERT(VARCHAR(10), DATEADD(DAY, ValidDays, GETDATE()), 120)
               WHEN ValidType = 2 THEN '9999-12-31'
               WHEN ValidType = 3 THEN CONVERT(VARCHAR(10), ExpiredDate, 120)
           END AS ExpiredDate,
           d.TicketDiscount
    FROM VIP_ProMotion a
    JOIN VIP_Promotion_MemberNos b ON a.Pro_Code = b.Pro_Code AND a.EnterPriseID = b.EnterPriseID
    JOIN VIP_Promotion_Ticket c ON a.Pro_Code = c.Pro_Code AND a.EnterPriseID = c.EnterPriseID
    JOIN VIP_TicketType d ON c.TicketTypeCode = d.TicketTypeCode AND c.EnterPriseID = d.EnterPriseID
    JOIN VIP_Info e ON b.MemberNO = e.MemberNO AND b.EnterPriseID = e.EnterPriseID
    WHERE a.Pro_Code = @pro_code AND a.EnterPriseID = @enterpriseid;

    OPEN cursor0;

    FETCH NEXT FROM cursor0 INTO @MemberNO, @CardID, @CardNO, @TicketTypeCode, @PresentTicketCount,
                                 @ShopID, @TicketPrice, @ExpiredDate, @TicketDiscount;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @time2 = GETDATE();
        SET @tcount = 1;

        WHILE @tcount <= @PresentTicketCount
        BEGIN
            SET @ticketinfoid = NEWID();
            SET @tradenum = NEWID();

            INSERT INTO VIP_TicketInfo (
                GID, EnterPriseID, TicketInfoID, TradeNum, MemberNO, CardNO, CardID,
                TicketTypeCode, StartTicketCount, TicketCount, TicketPrice, TicketTotal, StartTicketTotal,
                TicketBgnNo, TicketEndNo,
                TicketExpiredDate,
                GenTradetime, Remark, CardTradeNum, GenReason, TradeRuleCode
            )
            VALUES (
                NEWID(), @enterpriseid, @ticketinfoid, @tradenum, @MemberNO, @CardNO, @CardID,
                @TicketTypeCode, 1, 1, @TicketPrice, @TicketPrice, 1,
                @ticketinfoid, @ticketinfoid,
                @ExpiredDate,
                @time1, '促銷贈券', @cardtradenum, 'VipProMotion', @pro_code
            );

            INSERT INTO VIP_Trade_Ticket (
                GID, EnterPriseID, TradeTime, TradeNum, MemberNO, CardNO, CardID,
                ShopID, TicketInfoID, TicketCount, TicketPrice, TicketTotal,
                TicketTypeCode, TicketBgnNO, TicketEndNo, CardTradeNum, TicketDisCount, LastModify, TradeTypeCode
            )
            VALUES (
                NEWID(), @enterpriseid, @time2, @tradenum, @MemberNO, @CardNO, @CardID,
                @ShopID, @ticketinfoid, 1, @TicketPrice, @TicketPrice,
                @TicketTypeCode, @ticketinfoid, @ticketinfoid, @cardtradenum, @TicketDisCount, @time2, '1'
            );

            SET @tcount = @tcount + 1;
        END;

        FETCH NEXT FROM cursor0 INTO @MemberNO, @CardID, @CardNO, @TicketTypeCode, @PresentTicketCount,
                                     @ShopID, @TicketPrice, @ExpiredDate, @TicketDiscount;
    END;

    CLOSE cursor0;
    DEALLOCATE cursor0;

    UPDATE VIP_TicketInfo
    SET MAC = SUBSTRING(sys.fn_sqlvarbasetostr(HASHBYTES('MD5',
        CAST(b.MemberNO AS VARCHAR(50)) +
        CAST(b.CardID AS VARCHAR(50)) +
        CAST(b.CardNO AS VARCHAR(50)) +
        b.TradeNum +
        CAST(ISNULL(b.OrderID,'') AS VARCHAR(50)) +
        CAST(ISNULL(b.OrderNO,'') AS VARCHAR(50)) +
        CAST(ISNULL(b.CheckID,'') AS VARCHAR(50)) +
        CAST(ISNULL(b.ItemID,'') AS VARCHAR(50)) +
        CAST(ISNULL(b.FoodKind,'') AS VARCHAR(50)) +
        CAST(ISNULL(b.FoodID,'') AS VARCHAR(50)) +
        CAST(ISNULL(b.TicketTotal,0) AS VARCHAR(10)) + '.00' +
        b.TicketInfoID +
        b.TicketTypeCode +
        CAST(ISNULL(b.TicketPrice,0) AS VARCHAR(10)) + '.00' +
        b.TicketInfoID +
        b.TicketTypeCode +
        CAST(ISNULL(b.TicketPrice,0) AS VARCHAR(10)) +
        CAST(ISNULL(b.Operator,'') AS VARCHAR(50)) +
        CAST(ISNULL(b.OldTradeNum,'') AS VARCHAR(50))
    )), 3, 32)
    FROM VIP_TicketInfo a
    JOIN VIP_Trade_Ticket b ON a.EnterPriseID = b.EnterPriseID AND a.TradeNum = b.TradeNum
    WHERE a.TradeRuleCode = @pro_code
      AND a.EnterPriseID = @enterpriseid
      AND a.CardTradeNum = @cardtradenum;

    UPDATE VIP_Trade_Ticket
    SET MAC = a.MAC
    FROM VIP_TicketInfo a
    JOIN VIP_Trade_Ticket b ON a.EnterPriseID = b.EnterPriseID AND a.TradeNum = b.TradeNum
    WHERE a.TradeRuleCode = @pro_code
      AND a.EnterPriseID = @enterpriseid
      AND a.CardTradeNum = @cardtradenum;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorCode;
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;

/* 
UPDATE VIP_ProMotion
SET status = 2
WHERE EnterPriseID = :EnterPriseID
  AND GID = ':GID'
  AND status = 1;
*/