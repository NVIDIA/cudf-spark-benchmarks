
WITH customer_sales AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_net_paid ELSE 0 END) AS total_store_sales,
        SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_net_paid ELSE 0 END) AS total_catalog_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_first_name, c.c_last_name
),
sales_comparison AS (
    SELECT 
        c_first_name,
        c_last_name,
        total_store_sales,
        total_web_sales,
        total_catalog_sales,
        RANK() OVER (ORDER BY total_store_sales DESC) AS store_sales_rank,
        RANK() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank
    FROM 
        customer_sales
)
SELECT 
    c_first_name,
    c_last_name,
    total_store_sales,
    total_web_sales,
    total_catalog_sales,
    store_sales_rank,
    web_sales_rank,
    catalog_sales_rank,
    CONCAT(CAST(store_sales_rank AS STRING), ' | ', CAST(web_sales_rank AS STRING), ' | ', CAST(catalog_sales_rank AS STRING)) AS sales_rank_combined
FROM 
    sales_comparison
WHERE 
    total_store_sales > 0 OR total_web_sales > 0 OR total_catalog_sales > 0
ORDER BY 
    total_store_sales DESC, total_web_sales DESC, total_catalog_sales DESC
LIMIT 100;
