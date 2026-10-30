
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(total_web_sales, 0) AS web_sales,
        COALESCE(total_catalog_sales, 0) AS catalog_sales,
        COALESCE(total_store_sales, 0) AS store_sales,
        web_order_count + catalog_order_count + store_order_count AS total_order_count
    FROM CustomerSales c
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.web_sales,
    ss.catalog_sales,
    ss.store_sales,
    ss.total_order_count,
    CASE 
        WHEN ss.total_order_count = 0 THEN 'No Orders'
        WHEN ss.web_sales > ss.catalog_sales AND ss.web_sales > ss.store_sales THEN 'Web Sales Dominant'
        WHEN ss.catalog_sales > ss.store_sales THEN 'Catalog Sales Dominant'
        ELSE 'Store Sales Dominant'
    END AS dominant_channel
FROM SalesSummary ss
ORDER BY ss.total_order_count DESC, ss.web_sales DESC;
