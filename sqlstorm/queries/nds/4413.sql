
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq = 6) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq = 6 AND d.d_dom <= 30)
),
HighProfitSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
)
SELECT 
    ca.ca_city,
    SUM(hp.ws_quantity) AS total_quantity,
    AVG(hp.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT hp.ws_order_number) AS order_count
FROM 
    customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN HighProfitSales hp ON c.c_customer_sk = hp.ws_item_sk
GROUP BY 
    ca.ca_city
HAVING 
    SUM(hp.ws_quantity) > 50
ORDER BY 
    avg_net_profit DESC
LIMIT 10;
