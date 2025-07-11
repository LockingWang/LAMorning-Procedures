-- 查詢會員資訊
DECLARE @MemberNO NVARCHAR(20) = '0975011014';
DECLARE @LineName NVARCHAR(10) = 'SUNNY';
DECLARE @EnterpriseID NVARCHAR(20) = 'XF42792721';

SELECT * FROM [NCW_xurf].[dbo].[VIP_CardInfo]
  WHERE MemberNO = @MemberNO
  AND EnterpriseID = @EnterpriseID;

SELECT * FROM [NCW_xurf].[dbo].[VIP_Info]
  WHERE MemberNO = @MemberNO
  AND EnterpriseID = @EnterpriseID;

SELECT * FROM [NCW_xurf].[dbo].[O_Members]
  WHERE Account = @MemberNO
  AND EnterpriseID = @EnterpriseID;
  
SELECT * FROM [NCW_xurf].[dbo].[O_MembersThird]
  WHERE MT_NickName = @LineName
  AND EnterpriseID = @EnterpriseID