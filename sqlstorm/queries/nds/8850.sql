
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
Sales_Analysis AS (
    SELECT 
        c.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(cs.total_web_sales, 0) = 0 AND COALESCE(cs.total_catalog_sales, 0) = 0 AND COALESCE(cs.total_store_sales, 0) = 0 THEN 'No Sales'
            WHEN COALESCE(cs.total_web_sales, 0) > COALESCE(cs.total_catalog_sales, 0) AND COALESCE(cs.total_web_sales, 0) > COALESCE(cs.total_store_sales, 0) THEN 'Web Sales Leading'
            WHEN COALESCE(cs.total_catalog_sales, 0) > COALESCE(cs.total_web_sales, 0) AND COALESCE(cs.total_catalog_sales, 0) > COALESCE(cs.total_store_sales, 0) THEN 'Catalog Sales Leading'
            WHEN COALESCE(cs.total_store_sales, 0) > COALESCE(cs.total_web_sales, 0) AND COALESCE(cs.total_store_sales, 0) > COALESCE(cs.total_catalog_sales, 0) THEN 'Store Sales Leading'
            ELSE 'Mixed Sales'
        END AS sales_category
    FROM Customer_Sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    sales_category,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS aggregate_sales
FROM Sales_Analysis
GROUP BY sales_category
ORDER BY customer_count DESC, aggregate_sales DESC;
