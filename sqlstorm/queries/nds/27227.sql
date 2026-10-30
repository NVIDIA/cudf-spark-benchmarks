
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesBenchmark AS (
    SELECT 
        total_sales,
        web_order_count,
        catalog_order_count,
        store_order_count,
        CASE 
            WHEN total_sales > 10000 THEN 'High Value'
            WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM CustomerSales
)
SELECT 
    customer_value_category,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS average_sales,
    SUM(web_order_count) AS total_web_orders,
    SUM(catalog_order_count) AS total_catalog_orders,
    SUM(store_order_count) AS total_store_orders
FROM SalesBenchmark
GROUP BY customer_value_category
ORDER BY customer_value_category;
