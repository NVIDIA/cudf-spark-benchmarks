
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_sales,
        total_orders,
        avg_sales_price,
        unique_web_pages,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    tc.avg_sales_price,
    tc.unique_web_pages,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        WHEN tc.sales_rank <= 50 THEN 'Mid-tier Customer'
        ELSE 'Low-tier Customer'
    END AS customer_tier
FROM 
    top_customers AS tc
ORDER BY 
    tc.total_sales DESC;
