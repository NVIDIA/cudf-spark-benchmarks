
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesStatistics AS (
    SELECT 
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        CASE 
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) = 0 THEN 0
            ELSE total_web_sales * 1.0 / (total_web_sales + total_catalog_sales + total_store_sales) 
        END AS web_sales_ratio,
        CASE 
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) = 0 THEN 0
            ELSE total_catalog_sales * 1.0 / (total_web_sales + total_catalog_sales + total_store_sales) 
        END AS catalog_sales_ratio,
        CASE 
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) = 0 THEN 0
            ELSE total_store_sales * 1.0 / (total_web_sales + total_catalog_sales + total_store_sales) 
        END AS store_sales_ratio
    FROM 
        CustomerSales
)
SELECT 
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales,
    AVG(total_sales) AS avg_total_sales,
    AVG(web_sales_ratio) AS avg_web_sales_ratio,
    AVG(catalog_sales_ratio) AS avg_catalog_sales_ratio,
    AVG(store_sales_ratio) AS avg_store_sales_ratio
FROM 
    SalesStatistics
WHERE 
    total_sales > 0
