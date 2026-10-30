
WITH  top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_spent DESC
    LIMIT 10
),
date_sales AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM date_dim dd
    LEFT JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY dd.d_date
)
SELECT 
    ds.d_date,
    ds.daily_sales,
    COALESCE(ds.daily_sales, 0) / NULLIF(SUM(ds.daily_sales) OVER (), 0) AS sales_percentage,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent
FROM date_sales ds
FULL OUTER JOIN top_customers tc ON 1=1 
ORDER BY ds.d_date DESC, tc.total_spent DESC
LIMIT 50;
