-- 今年的每一天、每一個時段訂單數量
SELECT 
    YEAR(LastModify) AS OrderYear,
    MONTH(LastModify) AS OrderMonth,
    DAY(LastModify) AS OrderDay,
    DATEPART(HOUR, LastModify) AS OrderHour,
    COUNT(*) AS OrderCount
FROM P_OrdersTemp_Web
WHERE YEAR(LastModify) = YEAR(GETDATE())
GROUP BY YEAR(LastModify), MONTH(LastModify), DAY(LastModify), DATEPART(HOUR, LastModify)
ORDER BY OrderMonth, OrderDay, OrderHour;

-- 找出數量最多的日期與時段
WITH OrderStats AS (
    SELECT 
        YEAR(LastModify) AS OrderYear,
        MONTH(LastModify) AS OrderMonth,
        DAY(LastModify) AS OrderDay,
        DATEPART(HOUR, LastModify) AS OrderHour,
        COUNT(*) AS OrderCount
    FROM P_OrdersTemp_Web
    WHERE YEAR(LastModify) = YEAR(GETDATE())
    GROUP BY YEAR(LastModify), MONTH(LastModify), DAY(LastModify), DATEPART(HOUR, LastModify)
)
SELECT *
FROM OrderStats
WHERE OrderCount = (SELECT MAX(OrderCount) FROM OrderStats)
ORDER BY OrderMonth, OrderDay, OrderHour;

