
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count,
        AVG(ws.ws_net_paid) AS avg_web_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),

StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count,
        AVG(ss.ss_net_paid) AS avg_store_order_value
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),

SalesComparison AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.web_order_count,
        cs.avg_web_order_value,
        ss.total_store_sales,
        ss.store_order_count,
        ss.avg_store_order_value
    FROM 
        CustomerSales cs
    JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
)

SELECT 
    s.c_customer_sk,
    COALESCE(s.total_web_sales, 0) AS total_web_sales,
    COALESCE(s.web_order_count, 0) AS web_order_count,
    COALESCE(s.avg_web_order_value, 0) AS avg_web_order_value,
    COALESCE(s.total_store_sales, 0) AS total_store_sales,
    COALESCE(s.store_order_count, 0) AS store_order_count,
    COALESCE(s.avg_store_order_value, 0) AS avg_store_order_value,
    (CASE 
        WHEN COALESCE(s.total_web_sales, 0) = 0 THEN 0
        ELSE (COALESCE(s.total_store_sales, 0) / COALESCE(s.total_web_sales, 1))
    END) AS store_to_web_sales_ratio
FROM 
    SalesComparison s
ORDER BY 
    s.c_customer_sk;
