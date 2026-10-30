
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        ss.total_sales,
        ss.online_orders,
        ss.catalog_orders,
        ss.store_orders,
        c.c_first_name,
        c.c_last_name
    FROM 
        sales_summary ss
    JOIN customer c ON ss.c_customer_id = c.c_customer_id
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS customer_name,
    tc.total_sales,
    tc.online_orders,
    tc.catalog_orders,
    tc.store_orders,
    CASE 
        WHEN tc.total_sales >= 1000 THEN 'High Value'
        WHEN tc.total_sales >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;
