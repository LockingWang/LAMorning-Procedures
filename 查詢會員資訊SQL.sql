-- 查詢會員資訊
DECLARE @MemberNO VARCHAR(10) = '0912954590';
DECLARE @LineName VARCHAR(10) = '';
DECLARE @EnterpriseID VARCHAR(10) = 'XF42792721';

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
  AND MT_ID = 'U59d4f2ba46d7e793bddf019de77f7690'