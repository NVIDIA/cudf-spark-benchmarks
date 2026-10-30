
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales AS ws
    JOIN item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        i.i_category,
        rs.total_quantity,
        rs.total_net_profit
    FROM RankedSales AS rs
    JOIN item AS i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.profit_rank = 1
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_city,
    tsi.i_item_desc,
    tsi.total_quantity AS quantity_sold,
    tsi.total_net_profit AS total_profit
FROM TopSellingItems AS tsi
JOIN store_sales AS ss ON tsi.ws_item_sk = ss.ss_item_sk
JOIN customer AS c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_city IS NOT NULL AND (ca.ca_state = 'NY' OR ca.ca_state = 'CA')
ORDER BY total_profit DESC, quantity_sold DESC
LIMIT 10;
