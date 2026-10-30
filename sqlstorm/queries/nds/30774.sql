
WITH  Sales_CTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_profit, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
Promotion_Summary AS (
    SELECT p.p_promo_sk, p.p_promo_name, COUNT(ws_order_number) AS total_sales, SUM(ws_net_profit) AS total_net_profit
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
      AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY p.p_promo_sk, p.p_promo_name
),
Top_Profitable_Items AS (
    SELECT sc.ws_item_sk, SUM(sc.ws_net_profit) AS total_net_profit
    FROM Sales_CTE sc
    GROUP BY sc.ws_item_sk
    ORDER BY total_net_profit DESC
    LIMIT 10
)
SELECT ca.ca_city, 
       COUNT(DISTINCT c.c_customer_id) AS customer_count,
       SUM(ws.ws_net_profit) AS total_sales_profit,
       MAX(promos.total_net_profit) AS max_promo_profit
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN Promotion_Summary promos ON ws.ws_promo_sk = promos.p_promo_sk
WHERE ca.ca_state = 'CA' 
  AND c.c_birth_year BETWEEN 1980 AND 1990
  AND ws.ws_sales_price IS NOT NULL
  AND (ws.ws_net_profit > 0 OR ws.ws_net_paid > 0)
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY total_sales_profit DESC;
