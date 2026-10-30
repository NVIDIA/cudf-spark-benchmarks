
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
        COALESCE(cs.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) AS total_sales
    FROM 
        customer_sales cs
),
top_customers AS (
    SELECT 
        s.c_customer_id,
        s.total_web_sales,
        s.total_catalog_sales,
        s.total_store_sales,
        s.total_sales,
        DENSE_RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    t.c_customer_id,
    t.total_web_sales,
    t.total_catalog_sales,
    t.total_store_sales,
    t.total_sales
FROM 
    top_customers t
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
