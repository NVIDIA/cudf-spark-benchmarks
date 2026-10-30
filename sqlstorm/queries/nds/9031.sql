
WITH yearly_sales AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
warehouse_stats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws_order_number) AS orders_fulfilled,
        SUM(ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ys.d_year,
    ys.total_sales,
    ys.total_orders,
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    ws.w_warehouse_id,
    ws.orders_fulfilled,
    ws.total_revenue
FROM 
    yearly_sales ys
CROSS JOIN 
    top_customers tc
JOIN 
    warehouse_stats ws ON ws.total_revenue > 100000
WHERE 
    ys.total_orders > 100
ORDER BY 
    ys.d_year DESC, tc.total_spent DESC, ws.total_revenue DESC;
