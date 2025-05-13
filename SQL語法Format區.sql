UPDATE P_FoodMould
SET 
    Sn = ':Sn',
    LastOP = :UserCode,
    LastModify = GetDate()
WHERE 
    EnterpriseID = :EnterpriseID 
    AND MouldCode = ':MouldCode'
    AND Kind = ':Kind'
    AND GID = ':GID'