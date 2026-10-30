
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales
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
SalesRanking AS (
    SELECT 
        c_customer_id, 
        total_web_sales, 
        total_catalog_sales, 
        total_store_sales,
        DENSE_RANK() OVER (ORDER BY total_web_sales DESC) AS web_rank,
        DENSE_RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_rank,
        DENSE_RANK() OVER (ORDER BY total_store_sales DESC) AS store_rank
    FROM 
        CustomerSales
), 
SalesSummary AS (
    SELECT 
        c_customer_id,
        web_rank, 
        catalog_rank,
        store_rank,
        COALESCE(total_web_sales, 0) AS web_sales,
        COALESCE(total_catalog_sales, 0) AS catalog_sales,
        COALESCE(total_store_sales, 0) AS store_sales,
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog'
            WHEN total_store_sales > total_web_sales AND total_store_sales > total_catalog_sales THEN 'Store'
            ELSE 'Tie'
        END AS primary_channel
    FROM 
        SalesRanking
)
SELECT 
    s.c_customer_id,
    s.web_rank,
    s.catalog_rank,
    s.store_rank,
    s.primary_channel,
    CASE 
        WHEN (s.web_sales IS NULL OR s.catalog_sales IS NULL OR s.store_sales IS NULL) THEN 'Missing Sales Data'
        ELSE 'Complete Sales Data'
    END AS data_status,
    (s.web_sales + s.catalog_sales + s.store_sales) AS total_sales
FROM 
    SalesSummary s
JOIN 
    (SELECT DISTINCT c.c_customer_id 
     FROM customer c 
     WHERE c.c_birth_month = 12 OR c.c_birth_month IS NULL) as customers_with_special_birthday ON s.c_customer_id = customers_with_special_birthday.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 10;
