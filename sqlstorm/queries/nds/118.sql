
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_overview AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        total_store_sales, 
        total_web_sales, 
        total_catalog_sales,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                            WHEN total_store_sales >= total_web_sales AND total_store_sales >= total_catalog_sales THEN 'In-Store'
                                            WHEN total_web_sales >= total_store_sales AND total_web_sales >= total_catalog_sales THEN 'Online'
                                            ELSE 'Catalog'
                                         END 
                           ORDER BY total_store_sales + total_web_sales + total_catalog_sales DESC) AS sales_rank
    FROM customer_sales c
)
SELECT 
    so.c_customer_sk, 
    so.c_first_name, 
    so.c_last_name, 
    so.total_store_sales,
    so.total_web_sales,
    so.total_catalog_sales,
    CASE 
        WHEN so.sales_rank <= 10 THEN 'Top 10 Customers'
        WHEN so.sales_rank <= 50 THEN 'Top 50 Customers'
        ELSE 'Others'
    END AS customer_category
FROM sales_overview so
WHERE (so.total_store_sales > 500 OR so.total_web_sales > 500 OR so.total_catalog_sales > 500)
ORDER BY so.total_store_sales + so.total_web_sales + so.total_catalog_sales DESC
LIMIT 100;
