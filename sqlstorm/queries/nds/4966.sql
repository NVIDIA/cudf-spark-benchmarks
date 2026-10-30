
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_web_sales + s.total_catalog_sales + s.total_store_sales AS total_sales,
        ROW_NUMBER() OVER (ORDER BY s.total_web_sales + s.total_catalog_sales + s.total_store_sales DESC) AS sales_rank
    FROM 
        customer_sales s
)

SELECT 
    ss.c_first_name,
    ss.c_last_name,
    ss.total_sales,
    CASE 
        WHEN ss.total_sales = 0 THEN 'No Sales'
        WHEN ss.total_sales > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    sales_summary ss
WHERE 
    ss.sales_rank <= 10
ORDER BY 
    ss.total_sales DESC;
