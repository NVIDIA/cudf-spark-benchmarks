
WITH top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY 
        d.d_year, d.d_month_seq
),
warehouse_stats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_customer_id,
    ss.d_year,
    ss.d_month_seq,
    ss.total_quantity,
    ss.total_net_profit,
    ws.w_warehouse_id,
    ws.total_orders,
    ws.total_items_sold,
    ws.total_revenue
FROM 
    top_customers tc
JOIN 
    sales_summary ss ON ss.d_month_seq IN (1, 2, 3)
JOIN 
    warehouse_stats ws ON ws.total_orders > 100
ORDER BY 
    total_spent DESC, ss.total_net_profit DESC;
