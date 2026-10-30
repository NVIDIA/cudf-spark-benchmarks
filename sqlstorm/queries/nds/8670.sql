
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
), 
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        cs.d_year,
        DENSE_RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_summary cs
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    tc.sales_rank,
    CONCAT('Year ', CAST(tc.d_year AS STRING), ': ', 
           CASE WHEN tc.sales_rank <= 10 THEN 'Top 10' ELSE 'Not Top 10' END) AS performance_tier
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.d_year, tc.sales_rank;
