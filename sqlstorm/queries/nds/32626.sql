
WITH  top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
date_range AS (
    SELECT 
        d.d_date_sk, 
        d.d_date 
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
sales_summary AS (
    SELECT 
        dr.d_date, 
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    INNER JOIN 
        date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY 
        dr.d_date
)
SELECT 
    ds.d_date,
    ds.total_orders,
    ds.total_profit,
    ds.avg_order_value,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent
FROM 
    sales_summary ds
LEFT JOIN 
    top_customers tc ON ds.total_profit > 5000
WHERE 
    ds.total_orders > 100
ORDER BY 
    ds.d_date DESC, ds.total_profit DESC
LIMIT 50;
