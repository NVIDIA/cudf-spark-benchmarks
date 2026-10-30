
WITH customer_totals AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spend_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_spent,
        c.total_orders,
        CASE 
            WHEN c.total_spent IS NULL THEN 'No Purchases'
            WHEN c.total_spent > 1000 THEN 'High Roller'
            ELSE 'Regular'
        END AS customer_category
    FROM 
        customer_totals c
    WHERE 
        c.spend_rank <= 10
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    hvc.customer_category,
    ws.total_sales,
    ws.avg_discount,
    ws.order_count
FROM 
    high_value_customers hvc
FULL OUTER JOIN 
    warehouse_sales ws ON hvc.customer_sk IS NULL AND ws.w_warehouse_sk IS NOT NULL
WHERE 
    (hvc.customer_category = 'High Roller' OR hvc.customer_category IS NULL)
    AND (ws.order_count > 0 OR ws.order_count IS NULL)
ORDER BY 
    hvc.total_spent DESC, 
    ws.total_sales DESC;
