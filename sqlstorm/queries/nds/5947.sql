
WITH RankedSales AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM store s
    JOIN web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY s.s_store_sk, s.s_store_name, ws.ws_sold_date_sk
),
TopStores AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        total_quantity, 
        total_net_profit
    FROM RankedSales
    WHERE rank <= 5
)
SELECT 
    ts.s_store_name,
    ts.total_quantity,
    ts.total_net_profit,
    ca.ca_city,
    ca.ca_state
FROM TopStores ts
JOIN customer_address ca ON ts.s_store_sk = ca.ca_address_sk
WHERE ca.ca_country = 'USA'
ORDER BY ts.total_net_profit DESC;
