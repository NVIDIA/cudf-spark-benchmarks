
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_addr_sk
),
store_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
total_sales AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS grand_total_sales,
        (COALESCE(cs.web_order_count, 0) + COALESCE(ss.store_order_count, 0)) AS total_orders
    FROM 
        customer_sales cs
    FULL OUTER JOIN 
        store_sales ss ON cs.c_customer_sk = ss.c_customer_sk
),
average_sales AS (
    SELECT 
        AVG(grand_total_sales) AS avg_grand_total_sales,
        AVG(total_orders) AS avg_order_count
    FROM 
        total_sales
)

SELECT 
    ts.c_customer_sk,
    ts.grand_total_sales AS total_sales,
    ts.total_orders,
    ROUND((ts.grand_total_sales / NULLIF(ts.total_orders, 0)), 2) AS avg_order_value,
    CASE 
        WHEN ts.grand_total_sales > (SELECT avg_grand_total_sales FROM average_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    total_sales ts
WHERE 
    ts.grand_total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
