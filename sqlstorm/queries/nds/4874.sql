
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) IS NOT NULL
),
seasonal_sales AS (
    SELECT 
        d.d_year,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2021
    GROUP BY 
        d.d_year
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS rnk
    FROM 
        customer_sales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    ss.total_store_sales,
    ss.store_transaction_count
FROM 
    top_customers tc
LEFT JOIN 
    seasonal_sales ss ON ss.d_year = (SELECT MAX(d_year) FROM seasonal_sales)
WHERE 
    tc.rnk <= 10
ORDER BY 
    tc.total_profit DESC;
