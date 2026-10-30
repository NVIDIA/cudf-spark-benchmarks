
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        COALESCE(s.total_web_sales, 0) AS total_web_sales,
        COALESCE(s.total_catalog_sales, 0) AS total_catalog_sales,
        COALESCE(s.total_store_sales, 0) AS total_store_sales,
        s.total_web_orders,
        s.total_catalog_orders,
        s.total_store_orders,
        RANK() OVER (ORDER BY (COALESCE(s.total_web_sales, 0) + COALESCE(s.total_catalog_sales, 0) + COALESCE(s.total_store_sales, 0)) DESC) AS sales_rank
    FROM 
        (SELECT DISTINCT c.c_customer_id, c.c_first_name, c.c_last_name FROM customer c) c
    LEFT JOIN 
        sales_summary s ON c.c_customer_id = s.c_customer_id
)
SELECT 
    customer_id,
    first_name,
    last_name,
    total_web_sales,
    total_catalog_sales,
    total_store_sales,
    total_web_orders,
    total_catalog_orders,
    total_store_orders,
    sales_rank
FROM 
    top_customers
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_rank;
