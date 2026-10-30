
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesStatistics AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        MAX(total_sales) AS max_sales,
        MIN(total_sales) AS min_sales,
        COUNT(c_customer_sk) AS total_customers,
        COUNT(CASE WHEN total_sales > 0 THEN 1 END) AS active_customers
    FROM 
        CustomerSales
)
SELECT 
    * 
FROM 
    SalesStatistics
WHERE 
    active_customers > 100
ORDER BY 
    avg_sales DESC
LIMIT 5;
