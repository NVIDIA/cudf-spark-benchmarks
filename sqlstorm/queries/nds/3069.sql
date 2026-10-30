
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) as rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_moy BETWEEN 1 AND 6
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_profit, 0) AS total_profit,
    COALESCE(tc.order_count, 0) AS order_count,
    (SELECT COUNT(*)
     FROM store_sales ss
     WHERE ss.ss_customer_sk = tc.c_customer_sk
     AND ss.ss_sold_date_sk IN (
         SELECT d_date_sk 
         FROM date_dim 
         WHERE d_year = 2023 AND d_moy BETWEEN 1 AND 6
     )
    ) AS store_order_count
FROM 
    top_customers tc
ORDER BY 
    tc.total_profit DESC
LIMIT 10;
