
WITH  AddressCTE AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_state, 
           CASE WHEN ca_city IS NULL THEN 'Unknown' ELSE ca_city END AS city_name,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS row_num
    FROM customer_address
    WHERE ca_state IN ('CA', 'TX')
), 
PromoSummary AS (
    SELECT p_promo_name, SUM(CASE WHEN p_start_date_sk < 2000000 THEN p_cost ELSE 0 END) AS total_cost,
           COUNT(DISTINCT p_promo_id) AS promo_count
    FROM promotion
    GROUP BY p_promo_name
), 
SalesSummary AS (
    SELECT ws_item_sk, ws_order_number, 
           SUM(ws_net_profit) OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM web_sales
    WHERE ws_order_number % 2 = 0
), 
InventoryLevels AS (
    SELECT inv_item_sk, 
           AVG(inv_quantity_on_hand) AS avg_quantity,
           MIN(inv_quantity_on_hand) AS min_quantity,
           MAX(inv_quantity_on_hand) AS max_quantity
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    a.ca_address_id, 
    a.city_name, 
    COALESCE(p.promo_count, 0) AS promo_count, 
    COALESCE(i.avg_quantity, 0) AS avg_quantity,
    s.cumulative_profit,
    CASE 
        WHEN s.profit_rank = 1 THEN 'Top Profit'
        WHEN s.profit_rank <= 5 THEN 'Top 5 Profits'
        ELSE 'Regular Profit'
    END AS profit_type
FROM AddressCTE a
FULL OUTER JOIN PromoSummary p ON a.row_num = p.promo_count
LEFT JOIN InventoryLevels i ON a.ca_address_sk = i.inv_item_sk
JOIN SalesSummary s ON a.ca_address_sk = s.ws_item_sk
WHERE a.row_num IS NOT NULL 
AND (i.avg_quantity IS NOT NULL OR a.ca_city = 'Los Angeles')
ORDER BY a.city_name, s.cumulative_profit DESC
LIMIT 100;
