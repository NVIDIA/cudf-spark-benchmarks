
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        COALESCE(total_web_sales, 0) AS web_sales,
        COALESCE(total_catalog_sales, 0) AS catalog_sales,
        COALESCE(total_store_sales, 0) AS store_sales,
        (COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0)) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY (COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0)) DESC) AS sales_rank
    FROM 
        CustomerSales c
),
RankedSales AS (
    SELECT *,
        CASE 
            WHEN total_sales = 0 THEN 'No Sales'
            WHEN total_sales < 1000 THEN 'Low Sales'
            WHEN total_sales >= 1000 AND total_sales <= 10000 THEN 'Moderate Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM 
        SalesSummary
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    r.sales_rank,
    r.sales_category,
    CASE 
        WHEN r.web_sales = 0 THEN 'Web Sales Not Available'
        ELSE CONCAT('Web Sales: ', r.web_sales)
    END AS web_sales_info,
    CASE 
        WHEN r.catalog_sales = 0 THEN 'Catalog Sales Not Available'
        ELSE CONCAT('Catalog Sales: ', r.catalog_sales)
    END AS catalog_sales_info,
    CASE 
        WHEN r.store_sales = 0 THEN 'Store Sales Not Available'
        ELSE CONCAT('Store Sales: ', r.store_sales)
    END AS store_sales_info
FROM 
    RankedSales r
WHERE 
    r.sales_category IS NOT NULL
ORDER BY 
    r.sales_rank
LIMIT 50;
