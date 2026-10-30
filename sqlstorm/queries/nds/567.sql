
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS catalog_sales,
        COALESCE(cs.total_store_sales, 0) AS store_sales
    FROM 
        CustomerSales cs
        RIGHT JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    address.ca_city, 
    SUM(ss.web_sales + ss.catalog_sales + ss.store_sales) AS total_sales,
    AVG(ss.web_sales) AS avg_web_sales,
    SUM(CASE WHEN ss.web_sales > 0 THEN 1 ELSE 0 END) AS count_web_sales,
    COUNT(DISTINCT ss.c_customer_sk) AS unique_customers,
    MAX(ss.store_sales) AS max_store_sales,
    COUNT(ss.catalog_sales) FILTER (WHERE ss.catalog_sales > 0) AS catalogs_with_sales
FROM 
    SalesSummary ss
    INNER JOIN customer_address address ON ss.c_customer_sk = address.ca_address_sk
WHERE 
    address.ca_state = 'CA' 
    AND (ss.web_sales > 500 OR ss.catalog_sales > 1000) 
GROUP BY 
    address.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
