-- 刪除會員資訊
DECLARE @MemberNO VARCHAR(20) = '0903008556';
DECLARE @LineName NVARCHAR(10) = N'王琮仁';
DECLARE @EnterpriseID VARCHAR(20) = 'XFlamorning';

DELETE FROM [NCW_xurf].[dbo].[O_MembersThird]
  WHERE EnterpriseID = @EnterpriseID
  AND MT_NickName = @LineName

DELETE FROM [NCW_xurf].[dbo].[VIP_CardInfo]
  WHERE MemberNO = @MemberNO
  AND EnterpriseID = @EnterpriseID;

DELETE FROM [NCW_xurf].[dbo].[VIP_Info]
  WHERE MemberNO = @MemberNO
  AND EnterpriseID = @EnterpriseID;

DELETE FROM [NCW_xurf].[dbo].[O_Members]
  WHERE Account = @MemberNO
  AND EnterpriseID = @EnterpriseID;

  
