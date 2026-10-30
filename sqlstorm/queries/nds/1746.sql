
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 0 AND (SELECT MAX(d_date_sk) FROM date_dim)
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
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_sales cs
),
return_stats AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_returned
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned, 0) AS total_returned,
    CASE 
        WHEN tc.total_spent > 1000 THEN 'High Value'
        WHEN tc.total_spent BETWEEN 500 AND 1000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM 
    top_customers tc
LEFT JOIN 
    return_stats rs ON tc.c_customer_sk = rs.cr_returning_customer_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
