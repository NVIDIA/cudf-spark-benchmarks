
WITH ranked_sales AS (
    SELECT
        ws_ship_customer_sk,
        ws_item_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_customer_sk ORDER BY ws_net_profit DESC) AS rnk,
        SUM(ws_net_profit) OVER (PARTITION BY ws_ship_customer_sk) AS total_profit
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
),
filtered_sales AS (
    SELECT
        rs.ws_ship_customer_sk,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.rnk,
        rs.total_profit,
        COALESCE((
            SELECT COUNT(*)
            FROM store_sales ss
            WHERE ss.ss_customer_sk = rs.ws_ship_customer_sk
              AND ss.ss_item_sk = rs.ws_item_sk
              AND ss.ss_ext_sales_price > 100
        ), 0) AS high_value_sales
    FROM ranked_sales rs
    WHERE rs.rnk <= 5
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT fs.ws_ship_customer_sk) AS unique_customers,
    SUM(fs.ws_quantity) AS total_quantity_sold,
    AVG(fs.total_profit) AS avg_profit
FROM filtered_sales fs
JOIN customer c ON c.c_customer_sk = fs.ws_ship_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN (
    SELECT
        sm_ship_mode_sk,
        sm_type
    FROM ship_mode
    WHERE sm_type LIKE '%air%'
) sm ON true
GROUP BY ca.ca_city
HAVING SUM(fs.high_value_sales) > 10
ORDER BY avg_profit DESC
LIMIT 10 OFFSET 0;
