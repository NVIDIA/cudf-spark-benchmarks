
WITH customer_orders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        co.total_net_profit,
        COALESCE(cd.cd_gender, 'U') AS gender
    FROM 
        customer_orders co
    LEFT JOIN 
        customer_demographics cd ON co.c_customer_sk = cd.cd_demo_sk
    WHERE 
        co.total_net_profit > (SELECT AVG(total_net_profit) FROM customer_orders)
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.gender,
    ROW_NUMBER() OVER (ORDER BY tc.total_net_profit DESC) AS profit_rank
FROM 
    top_customers tc
ORDER BY 
    tc.total_net_profit DESC
LIMIT 10;
