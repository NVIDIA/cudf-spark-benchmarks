
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM web_sales AS ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory AS inv
    GROUP BY inv.inv_item_sk
),
OutOfStockItems AS (
    SELECT 
        item.i_item_sk, 
        item.i_item_id 
    FROM item
    LEFT JOIN InventoryCheck AS ic ON item.i_item_sk = ic.inv_item_sk
    WHERE ic.total_quantity_on_hand IS NULL OR ic.total_quantity_on_hand = 0
),
SalesSummary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales AS cs
    GROUP BY cs.cs_item_sk
),
Promotions AS (
    SELECT 
        p.p_item_sk,
        COUNT(DISTINCT p.p_promo_id) AS promo_count
    FROM promotion AS p
    WHERE p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY p.p_item_sk
)

SELECT 
    ca.ca_address_id, 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    COALESCE(SUM(RS.ws_sales_price * RS.ws_quantity), 0) AS total_sales,
    COALESCE(SUM(SS.total_profit), 0) AS total_catalog_profit,
    MAX(PC.promo_count) AS max_promotions
FROM customer_address AS ca
JOIN customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN RankedSales AS RS ON RS.ws_item_sk = c.c_customer_sk
LEFT JOIN SalesSummary AS SS ON SS.cs_item_sk = c.c_customer_sk
LEFT JOIN Promotions AS PC ON PC.p_item_sk = c.c_current_cdemo_sk
WHERE ca.ca_state IS NOT NULL
AND (c.c_birth_day IS NULL OR c.c_birth_month IS NOT NULL)
GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT c.c_customer_id) > 1 
   OR COALESCE(SUM(RS.ws_sales_price * RS.ws_quantity), 0) > 1000
   OR MAX(PC.promo_count) > 2
ORDER BY total_sales DESC, customer_count DESC
LIMIT 10;
