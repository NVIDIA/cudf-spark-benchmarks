
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
ranked_sales AS (
    SELECT 
        c.c_customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        RANK() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        RANK() OVER (ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        customer_sales c
),
sales_summary AS (
    SELECT 
        c_customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        web_sales_rank,
        catalog_sales_rank,
        store_sales_rank,
        CASE 
            WHEN total_web_sales IS NULL THEN 'No Web Sales' 
            ELSE 'Has Web Sales' 
        END AS web_sales_status,
        CASE 
            WHEN total_catalog_sales IS NULL THEN 'No Catalog Sales' 
            ELSE 'Has Catalog Sales' 
        END AS catalog_sales_status,
        CASE 
            WHEN total_store_sales IS NULL THEN 'No Store Sales' 
            ELSE 'Has Store Sales' 
        END AS store_sales_status
    FROM 
        ranked_sales
)
SELECT 
    s.c_customer_id,
    COALESCE(s.total_web_sales, 0) AS web_sales_amount,
    COALESCE(s.total_catalog_sales, 0) AS catalog_sales_amount,
    COALESCE(s.total_store_sales, 0) AS store_sales_amount,
    s.web_sales_rank,
    s.catalog_sales_rank,
    s.store_sales_rank,
    s.web_sales_status,
    s.catalog_sales_status,
    s.store_sales_status
FROM 
    sales_summary s
WHERE 
    s.web_sales_rank <= 10 OR 
    s.catalog_sales_rank <= 10 OR 
    s.store_sales_rank <= 10
ORDER BY 
    COALESCE(s.total_web_sales, 0) DESC, 
    COALESCE(s.total_catalog_sales, 0) DESC,
    COALESCE(s.total_store_sales, 0) DESC;
