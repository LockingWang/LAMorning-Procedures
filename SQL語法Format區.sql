-- 會員卡優惠規則
if exists (select * from VIP_TradeRules where TradeRuleCode = ':TradeRuleCode')
begin
    select 1 as flag, '已經有被使用過' as text
end
else
begin
    declare
        @BeginDate date,
        @EndDate date,
        @BeginTime datetime,
        @EndTime datetime
    
    set @BeginDate = ':BeginDate'
    set @EndDate = ':EndDate'
    set @BeginTime = ':BeginTime'
    set @EndTime = ':EndTime'
    
    if (@BeginDate = '')
        set @BeginDate = null
    if (@EndDate = '')
        set @EndDate = null
    if (@BeginTime = '')
        set @BeginTime = null
    if (@EndTime = '')
        set @EndTime = null
    
    insert into VIP_TradeRules (
        GID, EnterPriseID, TradeRuleCode, TradeRuleName, CardTypeCode,
        Priority, TradeAmount, PresentPoint, IsTimes, BrithTimes,
        IsUseDate, MaxUseCount, UseCountIsShop, ConfirmUseCount, TradeTypeCode,
        BeginDate, EndDate, BeginTime, EndTime,
        Week1, Week2, Week3, Week4, Week5, Week6, Week7
    )
    values (
        ':GID', :EnterPriseID, ':TradeRuleCode', ':TradeRuleName', ':CardTypeCode',
        ':Priority', ':TradeAmount', ':PresentPoint', ':IsTimes', ':BrithTimes',
        ':IsUseDate', ':MaxUseCount', ':UseCountIsShop', ':ConfirmUseCount', '1',
        ':BeginDate', ':EndDate', ':BeginTime', ':EndTime',
        ':Week1', ':Week2', ':Week3', ':Week4', ':Week5', ':Week6', ':Week7'
    )
    
    select 0 as flag, '尚未被使用過,新增成功' as text
end


-- 優惠券使用規則
insert into VIP_TradeRules (
    GID, EnterPriseID, TradeRuleCode, TradeRuleName, CardTypeCode,
    Priority, BeginDate, EndDate, BirthDayRuleType, IsStopGive,
    Week1, Week2, Week3, Week4, Week5, Week6, Week7,
    BeginTime, EndTime, Remark, TradeTypeCode
) values (
    ':GID', :EnterPriseID, ':TradeRuleCode', ':TradeRuleName', ':CardTypeCode',
    ':Priority', ':BeginDate', ':EndDate', ':BirthDayRuleType', ':IsStopGive',
    ':Week1', ':Week2', ':Week3', ':Week4', ':Week5', ':Week6', ':Week7',
    null, null, ':Remark', 'T2'
)