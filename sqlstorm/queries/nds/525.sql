
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer_sales cs
),
return_data AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returned,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    COALESCE(rd.total_returned, 0) AS total_returned,
    COALESCE(rd.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(rd.total_returned, 0) > 0 THEN 'Returning'
        ELSE 'New'
    END AS customer_type
FROM top_customers tc
LEFT JOIN return_data rd ON tc.c_customer_sk = rd.sr_customer_sk
WHERE tc.customer_rank <= 10
ORDER BY tc.total_spent DESC;
