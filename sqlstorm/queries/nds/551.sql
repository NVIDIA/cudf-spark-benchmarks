WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesComparison AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) - COALESCE(ss.total_store_sales, 0)) AS sales_difference
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(sc.total_web_sales, 0) AS total_web_sales,
    COALESCE(sc.total_store_sales, 0) AS total_store_sales,
    sc.sales_difference,
    CASE 
        WHEN sc.sales_difference > 0 THEN 'Web Sales Higher'
        WHEN sc.sales_difference < 0 THEN 'Store Sales Higher'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM 
    SalesComparison sc
JOIN 
    customer c ON sc.c_customer_sk = c.c_customer_sk
WHERE 
    sc.sales_difference != 0 
ORDER BY 
    sc.sales_difference DESC
LIMIT 100;