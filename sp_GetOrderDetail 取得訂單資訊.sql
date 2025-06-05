CREATE PROCEDURE [dbo].[sp_GetOrderDetail] 
    @memberNo NVARCHAR(50),  -- 會員No 
    @langId NVARCHAR(10) = NULL,  -- 語系Id 
    @orderId NVARCHAR(50)   -- 訂單Id 
AS 
BEGIN 

		SELECT  
		    i.EnterpriseID, 
		    i.SHOPID, 
		    org.OrgName AS shopName, 
		    o.VIPNo, 
		    o.ID, 
		    CAST(1 AS BIT) AS isMainOrder, 
		 
		    -- 訂單主資料 (桌號、訂單類型、外送資料) 
		    ( 
		        SELECT  
		            o.SaleType AS [type], 
		            o.SaleTime AS orderDateTime, 
		            o.DeskID AS tableNo, 
		            ISNULL(o.Man, 0) + ISNULL(o.Woman, 0) + ISNULL(o.Child, 0) + ISNULL(o.Baby, 0) AS dineInCount, 
		            o.VipAddr AS deliveryAddress, 
		            o.VIPTel AS deliveryPhone, 
		            o.ReceiverName AS deliveryName 
		        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER 
		    ) AS orderType, 
		 
		    -- 主餐、附餐、加料資料 
		    ( 
		        SELECT  
		            f.GID AS uId, 
		            i.FoodID, 
		            i.FoodName, 
		            ISNULL(uf.Dir, '') AS imagePath, 
					CAST(0 AS BIT) AS isGift,	--寫死 
					i.Total AS originalPrice, 
		            CAST(i.Price AS INT) AS price, 
		            CAST(i.Count AS INT) AS quantity, 
		            i.AgioTotal AS discountAmount, 
		            i.AgioReason AS itemCoupons, 
		            i.Memo AS remark, 
		 
		            ( 
		                SELECT  
		                    s.Value AS AddName, 
		                    CAST(MIN(ISNULL(fa.Price, 0)) AS INT) AS AddCost, 
		                    COUNT(*) AS AddQuantity 
		                FROM STRING_SPLIT(i.[Add], ',') s 
		                LEFT JOIN P_FoodAdd fa  
		                    ON fa.Name = s.Value 
		                    AND fa.EnterpriseID = i.EnterpriseID 
		                    AND fa.Owner = i.FoodID 
		                WHERE s.Value <> '' 
		                GROUP BY s.Value 
		                FOR JSON PATH 
		            ) AS optionItems, 
		 
		            ( 
		                SELECT  
		                    a.FoodID AS foodId, 
		                    a.FoodName AS foodName, 
		                    ISNULL(uf2.Dir, '') AS imagePath, 
		 
		                    CAST(a.Price AS INT) AS additionalPrice, 
		                    CAST(a.Count AS INT) AS quantity, 
		                    a.Memo AS remark, 
		 
		                    ( 
		                        SELECT  
		                            s.Value AS AddName, 
		                            CAST(MIN(ISNULL(fa2.Price, 0)) AS INT) AS AddCost, 
		                            COUNT(*) AS AddQuantity 
		                        FROM STRING_SPLIT(a.[Add], ',') s 
		                        LEFT JOIN P_FoodAdd fa2  
		                            ON fa2.Name = s.Value 
		                            AND fa2.EnterpriseID = a.EnterpriseID 
		                            AND fa2.Owner = a.FoodID 
		                        WHERE s.Value <> '' 
		                        GROUP BY s.Value 
		                        FOR JSON PATH 
		                    ) AS optionItems 
		 
		                FROM P_ItemsTemp_Web a 
		                LEFT JOIN S_UploadFile uf2  
		                    ON a.FoodID = uf2.ItemID 
		                    AND a.EnterpriseID = uf2.EnterPriseID 
		                    AND uf2.vType = 'food2' 
		                WHERE a.MainID = i.FoodID 
		                AND a.OrderID = i.OrderID 
		                FOR JSON PATH 
		            ) AS comboItems 
		 
		        FROM P_ItemsTemp_Web i 
		        LEFT JOIN P_Food f ON i.FoodID = f.ID 
		        LEFT JOIN S_UploadFile uf  
		            ON i.FoodID = uf.ItemID 
		            AND i.EnterpriseID = uf.EnterPriseID 
		            AND uf.vType = 'food2' 
		        WHERE i.MainID = ''  
		        AND i.FoodID IS NOT NULL 
		        AND i.OrderID = o.ID 
		        FOR JSON PATH 
		    ) AS items,   
		 
		    ( 
		        SELECT  
		        	'電子發票' AS invoiceType,	--沒這欄位寫死 
		            inv.VendNo AS taxId, 
		            o.CarrierId AS carrierNo 
		        FROM P_Invoice inv 
		        WHERE inv.OrderID = o.ID 
		        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER 
		    ) AS invoice, 
		     
		    o.ReceiverMark AS orderRemark, 
		    o.OrderStatus, 
		    o.OrderNo AS shortOrderCode, 
		    o.OrderNo2 AS fullOrderCode, 
		    o.SaleTime AS orderDate, 
		    o.TakeWayTime AS pickupTime, 
		    o.PayChannel AS paymentMethod, 
		    o.PayTotal AS payamount 
		 
		FROM P_ItemsTemp_Web i 
		LEFT JOIN P_OrdersTemp_Web o ON i.OrderID = o.ID 
		LEFT JOIN S_Organ org  
		    ON i.EnterpriseID = org.EnterPriseID  
		    AND i.SHOPID = org.OrgCode 
		WHERE i.OrderID = 'e2c6cc50845d427d86066d035dc5f1eb' 
 
END