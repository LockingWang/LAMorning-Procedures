
DECLARE    @EnterpriseID varchar(50) = 'XFlamorning',
    @Account varchar(50) = '0909685758'

BEGIN
	SET NOCOUNT ON;

    
    delete from VIP_CardRePlenish from VIP_Info a,VIP_CardRePlenish b where a.EnterPriseID=b.EnterpriseID  and a.CardID=b.CardID  and a.EnterPriseID=@EnterpriseID  and  a.CardNO = @Account;

    delete from VIP_ExpiredPoints from VIP_Info a,VIP_ExpiredPoints b where a.EnterPriseID=b.EnterpriseID  and a.CardID=b.CardID  and a.EnterPriseID=@EnterpriseID  and  a.CardNO = @Account;
    delete from VIP_ExpiredPoints_Trade from VIP_Info a,VIP_ExpiredPoints_Trade b where a.EnterPriseID=b.EnterpriseID  and a.CardID=b.CardID  and a.EnterPriseID=@EnterpriseID  and  a.CardNO = @Account;
 
    delete from VIP_TicketInfo from VIP_Info a,VIP_TicketInfo b where a.EnterPriseID=b.EnterpriseID  and a.CardID=b.CardID  and a.EnterPriseID=@EnterpriseID  and  a.CardNO = @Account;
    delete from VIP_Trade from VIP_Info a,VIP_Trade b where a.EnterPriseID=b.EnterpriseID  and a.CardID=b.CardID  and a.EnterPriseID=@EnterpriseID  and  a.CardNO = @Account;
    delete from VIP_Trade_Ticket from VIP_Info a,VIP_Trade_Ticket b where a.EnterPriseID=b.EnterpriseID  and a.CardID=b.CardID  and a.EnterPriseID=@EnterpriseID  and  a.CardNO = @Account;
  
    delete from O_MembersThird where  EnterPriseID=@EnterpriseID  and  CreateUser = @Account;
    delete from  P_QRCodeActivityDetail where EnterPriseID=@EnterpriseID  and  CardNO = @Account;   
    delete from  O_FaceDetect where EnterPriseID=@EnterpriseID  and  MemberNO = @Account;  
    delete from  O_FaceAI where EnterPriseID=@EnterpriseID  and  Account = @Account;  
    
    delete from O_Members where  EnterPriseID=@EnterpriseID  and  Account = @Account;
    delete from VIP_Info where EnterPriseID=@EnterpriseID  and  CardNO = @Account;
    delete from VIP_CardInfo where  EnterPriseID=@EnterpriseID  and  CardNO = @Account;
END
GO
