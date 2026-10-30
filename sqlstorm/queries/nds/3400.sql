
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_activity AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    ca.c_first_name,
    ca.c_last_name,
    ra.ws_item_sk,
    ra.ws_order_number,
    ra.ws_net_profit
FROM 
    customer_activity ca
LEFT JOIN 
    ranked_sales ra ON ca.total_net_profit > 5000 AND ca.c_customer_sk IN (
        SELECT DISTINCT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_net_profit IS NOT NULL
    )
WHERE 
    ra.profit_rank = 1
    AND ca.total_purchases > 10
ORDER BY 
    ca.c_last_name, 
    ca.c_first_name, 
    ra.ws_net_profit DESC;
