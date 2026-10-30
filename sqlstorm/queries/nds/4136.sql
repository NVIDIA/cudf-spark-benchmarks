
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
RankedSales AS (
    SELECT 
        c.customer_id,
        c.total_web_sales,
        c.total_catalog_sales,
        c.total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                              WHEN c.total_web_sales > c.total_catalog_sales AND c.total_web_sales > c.total_store_sales THEN 'Web'
                                              WHEN c.total_catalog_sales > c.total_web_sales AND c.total_catalog_sales > c.total_store_sales THEN 'Catalog'
                                              ELSE 'Store'
                                          END ORDER BY c.total_web_sales DESC) AS sales_rank
    FROM CustomerSales c
)
SELECT 
    customer_id,
    total_web_sales,
    total_catalog_sales,
    total_store_sales,
    sales_rank,
    CASE 
        WHEN sales_rank = 1 THEN 'Top Performer'
        WHEN sales_rank <= 5 THEN 'High Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM RankedSales
WHERE total_web_sales IS NOT NULL 
  OR total_catalog_sales IS NOT NULL 
  OR total_store_sales IS NOT NULL
ORDER BY sales_rank;
