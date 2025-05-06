CREATE PROCEDURE [dbo].[sp_GetFoodOptions] 
    @enterpriseId NVARCHAR(50), -- 企業號
    @shopId NVARCHAR(50),       -- 門市ID(沒用到)
    @foodId NVARCHAR(50),       -- 餐點ID 
    @orderType NVARCHAR(50),    -- 訂單類型(模板類型，沒用到)
    @langId NVARCHAR(50) = NULL -- 語系ID
AS 

BEGIN 
    SET NOCOUNT ON; 
     
    -- SELECT  
    --     '1' AS ItemId,           -- 商品註記ID
    --     '加料選擇' AS ItemName,   -- 商品註記名稱
    --     '[ 
    --         { 
    --             "FoodId" : "1",      -- 註記ID
    --             "ImagePath": "",     -- 註記圖片路徑(註記沒有圖片)
    --             "FoodName": "加起司", -- 註記名稱
    --             "Description": "",   -- 註記描述(註記沒有描述)
    --             "Price": 15,         -- 註記價格
    --             "Sort": 1,           -- 註記排序
    --             "IsSoldOut": false   -- 註記是否售完(註記沒有此tag)
    --         }, 
    --         { 
    --             "FoodId" : "2", 
    --             "ImagePath": "", 
    --             "FoodName": "加溫泉蛋", 
    --             "Description": "", 
    --             "Price": 30, 
    --             "Sort": 1, 
    --             "IsSoldOut": false 
    --         } 
    --     ]' AS Items,         -- 選項或餐點清單 
    --     0 AS MinSelectCount, -- 最少選擇數量(非必選 = 0；必選 = 1) 
    --     2 AS MaxSelectCount  -- 最多可選數量 
                 
    --     UNION 
    -- SELECT  
    --     '2' AS ItemId,
    --     '辣度' AS ItemName,
    --     '[ 
    --         { 
    --             "FoodId" : "3", 
    --             "ImagePath": "", 
    --             "FoodName": "微辣", 
    --             "Description": "", 
    --             "Price": 0, 
    --             "Sort": 1, 
    --             "IsSoldOut":true 
    --         } 
                         
    --     ]' AS Items, 
    --     1 AS MinSelectCount, 
    --     1 AS MaxSelectCount

    SELECT 
        FAK.ID AS ItemId,
        ISNULL(JSON_VALUE(LANGKIND.Content, '$.' + @langId + '.Name'), FAK.Name) AS ItemName,
        (
            SELECT 
                CAST(FA2.ID AS NVARCHAR(50)) AS FoodId,
                '' AS ImagePath,
                ISNULL(JSON_VALUE(LANGADD.Content, '$.' + @langId + '.Name'), FA2.Name) AS FoodName,
                '' AS Description,
                FA2.Price,
                FA2.SN AS Sort,
                CAST(0 AS BIT) AS IsSoldOut
            FROM P_FoodAdd FA2 
            LEFT JOIN P_Data_Language_D LANGADD 
                ON LANGADD.EnterpriseID = @enterpriseid  
                AND LANGADD.SourceID = FA2.ID  
                AND LANGADD.TableName = 'FoodAdd'
            WHERE FA2.AddKindID = FAK.ID
            AND FA2.EnterpriseID = @enterpriseId
            AND FA2.Owner = @foodId
            ORDER BY FA2.SN
            FOR JSON PATH
        ) AS Items,
        CASE FAK.needed 
            WHEN 0 THEN 0
            WHEN 1 THEN 1
        END AS MinSelectCount,
        FAK.MaxCount AS MaxSelectCount
    FROM P_FoodAdd FA
    JOIN P_FoodAddKind FAK ON FAK.ID = FA.AddKindID
    LEFT JOIN P_Data_Language_D LANGKIND 
        ON LANGKIND.EnterpriseID = @enterpriseid  
        AND LANGKIND.SourceID = FAK.ID  
        AND LANGKIND.TableName = 'FoodAddKind'
    WHERE FA.EnterpriseID = @enterpriseId 
    AND FA.Owner = @foodId
    GROUP BY FAK.ID, FAK.Name, FAK.MaxCount, FAK.needed, LANGKIND.Content

END