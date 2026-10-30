WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesStats AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales'
            WHEN total_sales >= 1000 THEN 'High Value'
            WHEN total_sales >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category,
        total_sales,
        web_order_count + catalog_order_count + store_order_count AS total_order_count
    FROM 
        CustomerSales c
)
SELECT 
    ss.c_customer_sk,
    ss.sales_category,
    ss.total_sales,
    ss.total_order_count,
    ROW_NUMBER() OVER (PARTITION BY ss.sales_category ORDER BY ss.total_sales DESC) AS rank_within_category,
    AVG(ss.total_sales) OVER () AS avg_total_sales
FROM 
    SalesStats ss
WHERE 
    ss.total_sales IS NOT NULL
    AND ss.total_order_count > 0
ORDER BY 
    ss.sales_category, ss.total_sales DESC
LIMIT 50;