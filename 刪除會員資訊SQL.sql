-- 刪除會員資訊
DECLARE @MemberNO VARCHAR(10) = '0903008556';
DECLARE @LineName VARCHAR(10) = '王琮仁';
DECLARE @EnterpriseID VARCHAR(10) = 'XF42792721';

DELETE FROM [NCW_xurf].[dbo].[O_MembersThird]
  WHERE MT_NickName = @LineName
  AND EnterpriseID = @EnterpriseID;

DELETE FROM [NCW_xurf].[dbo].[VIP_CardInfo]
  WHERE MemberNO = @MemberNO
  AND EnterpriseID = @EnterpriseID;

DELETE FROM [NCW_xurf].[dbo].[VIP_Info]
  WHERE MemberNO = @MemberNO
  AND EnterpriseID = @EnterpriseID;

DELETE FROM [NCW_xurf].[dbo].[O_Members]
  WHERE Account = @MemberNO
  AND EnterpriseID = @EnterpriseID;