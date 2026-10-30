
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY ws.ws_order_number, ws.ws_item_sk
),
top_selling_items AS (
    SELECT
        sd.ws_item_sk,
        COUNT(sd.ws_order_number) AS order_count,
        AVG(sd.total_net_profit) AS avg_profit_per_order
    FROM sales_data sd
    WHERE sd.rank_profit <= 10
    GROUP BY sd.ws_item_sk
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS total_customer_profit
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(ss.ss_net_profit) IS NOT NULL
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(COALESCE(cs.total_customer_profit, 0)) AS total_profit,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
    MIN(cs.total_customer_profit) AS min_profit,
    MAX(cs.total_customer_profit) AS max_profit
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
JOIN top_selling_items tsi ON tsi.ws_item_sk IN (
    SELECT i.i_item_sk
    FROM item i
    WHERE i.i_current_price > 20.00
)
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT cs.c_customer_sk) > 5
ORDER BY total_profit DESC
LIMIT 20;
