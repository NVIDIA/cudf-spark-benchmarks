
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
SalesSummary AS (
    SELECT
        CASE
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog'
            WHEN total_store_sales > total_web_sales AND total_store_sales > total_catalog_sales THEN 'Store'
            ELSE 'Equal'
        END AS Max_Sales_Channel,
        COUNT(c_customer_id) AS customer_count
    FROM CustomerSales
    GROUP BY Max_Sales_Channel
)
SELECT
    Max_Sales_Channel,
    customer_count,
    ROUND((customer_count * 100.0 / SUM(customer_count) OVER ()), 2) AS percentage
FROM SalesSummary
ORDER BY customer_count DESC;
