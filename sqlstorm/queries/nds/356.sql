
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders
    FROM 
        customer_sales cs
    WHERE 
        cs.rank <= 10
),
warehouse_info AS (
    SELECT
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_processed,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(w.total_revenue, 0) AS total_revenue_by_warehouse,
    tc.total_spent AS customer_total_spent,
    (SELECT COUNT(*)
     FROM store_returns sr
     WHERE sr.sr_customer_sk = tc.c_customer_sk 
       AND sr.sr_return_quantity > 0) AS returns_count
FROM 
    top_customers tc
LEFT JOIN 
    warehouse_info w ON w.orders_processed > 0
ORDER BY 
    tc.total_spent DESC, total_revenue_by_warehouse DESC;
