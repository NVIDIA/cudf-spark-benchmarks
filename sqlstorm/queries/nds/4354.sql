
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                               AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        customer_sales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_spent, 0) AS total_spent,
    CASE 
        WHEN tc.total_orders > 0 THEN ROUND(tc.total_spent / tc.total_orders, 2)
        ELSE NULL
    END AS avg_spent_per_order,
    CASE 
        WHEN tc.customer_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM 
    top_customers tc
WHERE 
    tc.customer_rank <= 10
UNION ALL
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_spent, 0) AS total_spent,
    CASE 
        WHEN tc.total_orders > 0 THEN ROUND(tc.total_spent / tc.total_orders, 2)
        ELSE NULL
    END AS avg_spent_per_order,
    CASE 
        WHEN tc.customer_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM 
    top_customers tc
WHERE 
    tc.customer_rank > 10
ORDER BY 
    total_spent DESC;
