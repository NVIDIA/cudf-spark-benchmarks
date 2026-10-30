
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND ws.ws_sales_price IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS OrderCount,
        SUM(ws.ws_quantity) AS TotalQuantity,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS AvgPurchaseEstimate
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS TotalInventory,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS WarehouseCount
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
PromotionPerformance AS (
    SELECT 
        p.p_promo_sk,
        COUNT(ws.ws_order_number) AS OrderCount,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS TotalRevenue
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        p.p_promo_sk
),
FinalReport AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(SUM(cs.TotalQuantity), 0) AS TotalSold,
        ps.TotalRevenue,
        MAX(CASE WHEN ps.TotalRevenue IS NOT NULL THEN 'Promo Applied' ELSE 'No Promo' END) AS PromoStatus,
        COALESCE(ROUND(AVG(r.ws_sales_price), 2), 0) AS AvgPrice,
        COUNT(DISTINCT r.ws_item_sk) AS HighValueItems
    FROM 
        CustomerStats cs
    LEFT JOIN 
        PromotionPerformance ps ON ps.OrderCount > 0
    LEFT JOIN 
        RankedSales r ON cs.OrderCount = r.SalesRank 
    LEFT JOIN 
        InventoryCheck inv ON inv.inv_item_sk = r.ws_item_sk
    GROUP BY 
        cs.c_customer_sk, ps.TotalRevenue
)
SELECT 
    c.c_customer_id,
    f.TotalSold,
    f.TotalRevenue,
    CASE 
        WHEN f.TotalSold = 0 THEN 'No Sales' 
        WHEN f.TotalSold > 100 THEN 'High Volume' 
        ELSE 'Regular' 
    END AS SalesCategory,
    f.AvgPrice,
    f.PromoStatus
FROM 
    FinalReport f
JOIN 
    customer c ON f.c_customer_sk = c.c_customer_sk
WHERE 
    EXISTS (SELECT 1 FROM customer_demographics cd WHERE cd.cd_demo_sk = c.c_current_cdemo_sk AND cd.cd_gender = 'F')
ORDER BY 
    f.TotalSold DESC, f.TotalRevenue DESC
LIMIT 100;
