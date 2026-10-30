
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
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
        COALESCE(cs.total_orders, 0) AS total_web_orders,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        COALESCE(ss.total_store_orders, 0) AS total_store_orders
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
)
SELECT 
    c.c_customer_id,
    ROUND(AVG(total_web_sales + total_store_sales), 2) AS average_total_sales,
    ROUND(AVG(total_web_orders + total_store_orders), 2) AS average_order_count,
    COUNT(DISTINCT CASE 
        WHEN total_web_sales + total_store_sales > 0 THEN c.c_customer_id 
    END) AS active_customers
FROM 
    CombinedSales
JOIN 
    customer c ON CombinedSales.c_customer_sk = c.c_customer_sk
WHERE 
    (total_web_sales + total_store_sales) > 0
GROUP BY 
    c.c_customer_id
ORDER BY 
    average_total_sales DESC
LIMIT 10;
