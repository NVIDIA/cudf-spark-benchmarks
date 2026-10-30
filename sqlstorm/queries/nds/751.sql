WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT * 
    FROM customer_sales 
    WHERE spending_rank <= 10
),
order_dates AS (
    SELECT 
        d.d_date, 
        COUNT(ws.ws_order_number) AS daily_orders, 
        SUM(ws.ws_net_paid_inc_tax) AS daily_revenue 
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
combined_data AS (
    SELECT 
        tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
        tc.total_spent,
        tc.total_orders,
        COALESCE(od.daily_orders, 0) AS daily_orders,
        COALESCE(od.daily_revenue, 0) AS daily_revenue
    FROM top_customers tc
    FULL OUTER JOIN order_dates od ON 1=1  
)
SELECT 
    customer_name,
    total_spent,
    total_orders,
    daily_orders,
    daily_revenue,
    total_spent / NULLIF(total_orders, 0) AS avg_spent_per_order,
    CASE 
        WHEN daily_revenue = 0 THEN 'No Sales'
        ELSE 'Sales Present' 
    END AS sales_status,
    ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS row_num
FROM combined_data
ORDER BY total_spent DESC;