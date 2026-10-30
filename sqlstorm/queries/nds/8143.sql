
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
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
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CombinedSales AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(cs.total_web_orders, 0) AS total_web_orders,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        COALESCE(ss.total_store_orders, 0) AS total_store_orders
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_web_sales,
    cs.total_store_sales,
    cs.total_web_orders,
    cs.total_store_orders,
    (CS.total_web_sales + cs.total_store_sales) AS grand_total_sales
FROM 
    customer c
LEFT JOIN 
    CombinedSales cs ON c.c_customer_sk = cs.c_customer_sk
WHERE 
    (cs.total_web_sales + cs.total_store_sales) > 1000
ORDER BY 
    grand_total_sales DESC
LIMIT 100;
