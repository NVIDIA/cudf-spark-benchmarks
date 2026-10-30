
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_id
),
SalesComparison AS (
    SELECT 
        cs.c_customer_id,
        total_web_sales,
        total_catalog_sales,
        total_web_orders,
        total_catalog_orders,
        CASE 
            WHEN total_web_sales IS NULL THEN 'No Web Sales'
            WHEN total_catalog_sales IS NULL THEN 'No Catalog Sales'
            WHEN total_web_sales > total_catalog_sales THEN 'Web Sales Higher'
            WHEN total_web_sales < total_catalog_sales THEN 'Catalog Sales Higher'
            ELSE 'Equal Sales'
        END AS sales_comparison
    FROM CustomerSales cs
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank
    FROM SalesComparison
)
SELECT 
    rc.c_customer_id,
    rc.total_web_sales,
    rc.total_catalog_sales,
    rc.sales_comparison,
    rc.web_sales_rank,
    rc.catalog_sales_rank
FROM RankedCustomers rc
WHERE 
    rc.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
    OR rc.total_catalog_sales > (SELECT AVG(total_catalog_sales) FROM CustomerSales)
ORDER BY rc.sales_comparison, rc.total_web_sales DESC, rc.total_catalog_sales DESC;
