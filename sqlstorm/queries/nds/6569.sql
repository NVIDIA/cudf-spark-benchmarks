
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.total_sales,
        c.web_sales_count,
        c.store_sales_count,
        c.catalog_sales_count,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        customer_sales c
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_sales,
    tc.web_sales_count,
    tc.store_sales_count,
    tc.catalog_sales_count
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
