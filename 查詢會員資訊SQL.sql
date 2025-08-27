-- 查詢會員資訊
DECLARE @MemberNO NVARCHAR(20) = '0903008556';
DECLARE @EnterpriseID NVARCHAR(20) = 'XFlamorning';

SELECT * FROM [NCW_xurf].[dbo].[VIP_CardInfo]
  WHERE MemberNO = @MemberNO
  AND EnterpriseID = @EnterpriseID;

SELECT * FROM [NCW_xurf].[dbo].[VIP_Info]
  WHERE MemberNO = @MemberNO
  AND EnterpriseID = @EnterpriseID;

SELECT * FROM [NCW_xurf].[dbo].[O_Members]
  WHERE Account = @MemberNO
  AND EnterpriseID = @EnterpriseID;
  
SELECT * FROM [NCW_xurf].[dbo].[O_MembersThird] third
  JOIN O_Members member ON member.EnterpriseID = @EnterpriseID AND member.Account = @MemberNO AND member.GID = third.MB_GID
  WHERE third.EnterpriseID = @EnterpriseID


-- SELECT * FROM O_MembersThird
-- WHERE isFrom = 'APPLElogin'
