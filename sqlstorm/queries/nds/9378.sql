
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web Sales Leader'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog Sales Leader'
            WHEN total_store_sales > total_web_sales AND total_store_sales > total_catalog_sales THEN 'Store Sales Leader'
            ELSE 'Equal Sales'
        END AS sales_lead_category,
        COUNT(c_customer_id) AS customer_count,
        SUM(total_web_sales) AS total_web_sales,
        SUM(total_catalog_sales) AS total_catalog_sales,
        SUM(total_store_sales) AS total_store_sales
    FROM CustomerSales
    GROUP BY sales_lead_category
)

SELECT 
    sales_lead_category,
    customer_count,
    total_web_sales,
    total_catalog_sales,
    total_store_sales,
    (total_web_sales + total_catalog_sales + total_store_sales) AS grand_total_sales
FROM SalesSummary
ORDER BY grand_total_sales DESC;
