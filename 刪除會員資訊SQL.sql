-- 安全機制: 如果沒有抓到對應企業的對應會員，那就不會進行刪除，避免不小心把整個企業會員都刪除了
DECLARE @RC int
DECLARE @EnterpriseID varchar(50) = 'XFenjoy'
DECLARE @Account varchar(50) = '0903008556'
DECLARE @Confirm bit = 0 -- 安全保護碼(設為 1 才會確定執行)
DECLARE @PreviewOnly bit = 1 -- 預覽即將刪除的內容(設為 0 才會真的去刪除)

EXECUTE @RC = [dbo].[sp_Tool_MemberCleanup] 
   @EnterpriseID
  ,@Account
  ,@Confirm
  ,@PreviewOnly
GO