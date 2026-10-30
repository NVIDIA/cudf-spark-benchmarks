
WITH revenue_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        customer_summary.c_customer_sk,
        customer_summary.c_first_name,
        customer_summary.c_last_name,
        customer_summary.total_revenue,
        customer_summary.order_count,
        customer_summary.last_purchase_date,
        DENSE_RANK() OVER (ORDER BY customer_summary.total_revenue DESC) AS revenue_rank
    FROM 
        revenue_summary customer_summary
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_revenue,
    tc.order_count,
    tc.last_purchase_date
FROM 
    top_customers tc
WHERE 
    tc.revenue_rank <= 10
ORDER BY 
    tc.total_revenue DESC;
