CREATE PROCEDURE [dbo].[sp_CalculateOrderPreview] 
    @enterpriseId NVARCHAR(50), -- 企業號Id 
    @shopId NVARCHAR(50), -- 門市Id 
    @langId NVARCHAR(50) = NULL, -- 語系Id 
    @memberNo NVARCHAR(50) = NULL, -- 會員No 
    @orderUId NVARCHAR(50), -- 訂單UId 
    @isMainOrder BIT, -- 是否為主單 
    @orderType NVARCHAR(MAX), -- 訂單類型 (JSON格式) 
    @items NVARCHAR(MAX), -- 餐點清單 (JSON格式) 
    @orderCoupons NVARCHAR(MAX) = NULL, -- 整單優惠券清單 (JSON格式) 
    @orderDiscountAmount DECIMAL(18, 2) = 0 -- 整單折扣金額 
AS 
BEGIN 
    SET NOCOUNT ON; 
     
    SELECT  
        '[ 
            { 
                "imagePath": "/images/coupons/1.jpg", 
                "couponName": "全品項9折", 
                "count": 1, 
                "isAvailable": true, 
                "shopId": "S001", 
                "shopName": "台北信義店", 
                "unavailableReason": null, 
                "expiryDate": "2025-12-31T23:59:59" 
            } 
        ]' AS coupons, -- 優惠券清單 
        50.00 AS couponDiscountAmount, -- 優惠券折扣金額 
        '[ 
            { 
                "originalUId": "item001", 
                "discountAmount": 30.00, 
                "isEligible": true 
            } 
        ]' AS autoDiscounts, -- 自動套用優惠清單 
        '[ 
            { 
                "uId": "item001", 
                "foodId": "F001", 
                "isGift": false, 
                "isInvalid": false, 
                "isPriceChanged": false, 
                "originalPrice": 150.00, 
                "quantity": 2, 
                "price": 150.00, 
                "discountAmount": 15.00, 
                "itemCoupons": ["C001"], 
                "comboItems": null, 
                "options": null, 
                "remark": "少冰" 
            } 
        ]' AS updatedItems, -- 更新購物車清單 
        300.00 AS subtotal, -- 小計 
        235.00 AS total -- 總計 
END