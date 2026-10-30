
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
SalesSummary AS (
    SELECT 
        'Web' AS sale_type,
        SUM(total_web_sales) AS total_sales
    FROM CustomerSales
    WHERE total_web_sales IS NOT NULL
    UNION ALL
    SELECT 
        'Catalog' AS sale_type,
        SUM(total_catalog_sales) AS total_sales
    FROM CustomerSales
    WHERE total_catalog_sales IS NOT NULL
    UNION ALL
    SELECT 
        'Store' AS sale_type,
        SUM(total_store_sales) AS total_sales
    FROM CustomerSales
    WHERE total_store_sales IS NOT NULL
),
TopSales AS (
    SELECT 
        sale_type,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM SalesSummary
)
SELECT 
    sale_type,
    total_sales
FROM TopSales
WHERE rank = 1;
