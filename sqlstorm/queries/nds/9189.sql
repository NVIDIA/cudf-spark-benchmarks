
WITH top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20000101 AND 20231231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year
),
month_sales AS (
    SELECT 
        d.d_month_seq,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_net_paid) AS store_revenue
    FROM  
        store_sales ss
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_month_seq
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    ss.total_quantity_sold,
    ss.total_revenue,
    ms.store_quantity,
    ms.store_revenue
FROM 
    top_customers tc
JOIN 
    sales_summary ss ON true
JOIN 
    month_sales ms ON true
ORDER BY 
    tc.total_spent DESC;
