CREATE OR ALTER PROCEDURE [dbo].[sp_FindMemByLine]  
    @enterpriseId NVARCHAR(50) = NULL, -- 企業號Id  
    @lineUId NVARCHAR(100) -- line Id  
AS  
BEGIN  
    SET NOCOUNT ON;  
    SELECT   
        OM.Account AS MemberNO
    FROM   
        O_MembersThird OMT
    LEFT JOIN O_Members OM ON OMT.MB_GID = OM.GID
    WHERE   
        OMT.MT_ID = @lineUId 
        AND OMT.EnterpriseID = @enterpriseId 
END 