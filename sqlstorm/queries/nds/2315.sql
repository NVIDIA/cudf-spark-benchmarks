
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        cs.total_spent,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        customer_sales cs
    JOIN 
        (SELECT 
            c_customer_id, c_first_name, c_last_name 
         FROM 
            customer 
         WHERE 
            c_customer_sk IS NOT NULL) c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id,
    tc.first_name,
    tc.last_name,
    COALESCE(tc.total_spent, 0) AS total_spent,
    COALESCE(tc.order_count, 0) AS order_count,
    CASE 
        WHEN tc.spend_rank <= 10 THEN 'Top 10'
        WHEN tc.spend_rank <= 50 THEN 'Top 50'
        ELSE 'Other'
    END AS customer_category
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON tc.customer_id = CONCAT(ca.ca_address_id, 'CUST')
WHERE 
    ca.ca_state = 'NY'
ORDER BY 
    total_spent DESC;
