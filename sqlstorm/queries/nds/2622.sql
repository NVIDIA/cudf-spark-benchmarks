
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_web_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
StoreSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ss.ss_net_paid) AS total_store_sales, 
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sales_price > 100
    GROUP BY 
        c.c_customer_id
),
CombinedSales AS (
    SELECT 
        COALESCE(cs.c_customer_id, ss.c_customer_id) AS c_customer_id, 
        COALESCE(cs.total_web_sales, 0) AS total_web_sales, 
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0) AS total_combined_sales
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.c_customer_id
)

SELECT 
    c_customer_id AS customer_id, 
    total_web_sales, 
    total_store_sales, 
    total_combined_sales,
    CASE
        WHEN total_combined_sales > 1000 THEN 'High Value'
        WHEN total_combined_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CombinedSales
WHERE 
    total_combined_sales IS NOT NULL
ORDER BY 
    total_combined_sales DESC
LIMIT 50;
