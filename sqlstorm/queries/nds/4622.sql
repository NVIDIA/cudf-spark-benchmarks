
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
), 
SalesSummary AS (
    SELECT 
        c_customer_id,
        total_store_sales,
        total_web_sales,
        store_order_count,
        web_order_count,
        CASE 
            WHEN total_store_sales IS NULL AND total_web_sales IS NULL THEN 'No Sales'
            WHEN total_store_sales > total_web_sales THEN 'Store Dominant'
            WHEN total_web_sales > total_store_sales THEN 'Web Dominant'
            ELSE 'Equal Sales'
        END AS sales_category
    FROM 
        CustomerSales
)

SELECT 
    s.c_customer_id,
    COALESCE(s.total_store_sales, 0) AS store_sales,
    COALESCE(s.total_web_sales, 0) AS web_sales,
    s.store_order_count,
    s.web_order_count,
    s.sales_category,
    ROW_NUMBER() OVER (PARTITION BY s.sales_category ORDER BY s.total_store_sales + s.total_web_sales DESC) AS sales_rank
FROM 
    SalesSummary s
WHERE 
    (s.sales_category <> 'No Sales' OR (s.store_order_count > 0 AND s.web_order_count > 0))
ORDER BY 
    sales_category, sales_rank;
