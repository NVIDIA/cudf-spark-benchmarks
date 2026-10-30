
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        customer_sales cs
    WHERE 
        cs.sales_rank <= 10
),
sales_summary AS (
    SELECT 
        SUM(tc.total_sales) AS total_top_sales,
        AVG(tc.total_sales) AS average_sales,
        MAX(tc.total_sales) AS max_sales,
        MIN(tc.total_sales) AS min_sales
    FROM 
        top_customers tc
),
date_sales AS (
    SELECT 
        d.d_date,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS daily_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date >= (SELECT MIN(d2.d_date) FROM date_dim d2 WHERE d2.d_year = (SELECT MAX(d_year) FROM date_dim))
    GROUP BY 
        d.d_date
)
SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
    tc.total_sales,
    ss.total_top_sales,
    ss.average_sales,
    ss.max_sales,
    ss.min_sales,
    ds.daily_sales
FROM 
    top_customers tc
CROSS JOIN 
    sales_summary ss
LEFT JOIN 
    date_sales ds ON ds.daily_sales > ss.average_sales
ORDER BY 
    tc.total_sales DESC;
