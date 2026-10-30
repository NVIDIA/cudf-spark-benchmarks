WITH monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 1999 AND 2001
    GROUP BY 
        d.d_year, d.d_month_seq
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws_order_number) AS orders_from_warehouse,
        SUM(ws_ext_sales_price) AS total_sales_from_warehouse
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ms.d_year,
    ms.d_month_seq,
    ms.total_sales,
    ms.total_orders,
    ms.avg_net_paid,
    tc.c_customer_id,
    tc.order_count,
    tc.total_spent,
    ws.w_warehouse_id,
    ws.orders_from_warehouse,
    ws.total_sales_from_warehouse
FROM 
    monthly_sales ms
JOIN 
    top_customers tc ON ms.d_month_seq = tc.order_count  
JOIN 
    warehouse_summary ws ON ms.total_sales = ws.total_sales_from_warehouse  
ORDER BY 
    ms.d_year, ms.d_month_seq, tc.total_spent DESC;