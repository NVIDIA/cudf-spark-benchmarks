
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_sales cs
),
high_value_customers AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_spent
    FROM 
        top_customers tc
    WHERE 
        tc.rank <= 10
)
SELECT 
    hv.c_first_name,
    hv.c_last_name,
    COALESCE((SELECT COUNT(rr.r_reason_sk) 
              FROM web_returns wr 
              LEFT JOIN reason rr ON wr.wr_reason_sk = rr.r_reason_sk 
              WHERE wr.wr_returning_customer_sk = hv.c_customer_sk), 0) AS returns_count,
    CASE 
        WHEN hv.total_spent > 1000 THEN 'High Value'
        WHEN hv.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    high_value_customers hv
ORDER BY 
    returns_count DESC, hv.total_spent DESC;
