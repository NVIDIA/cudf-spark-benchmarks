
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    (SELECT COUNT(DISTINCT ws1.ws_order_number) 
     FROM web_sales ws1 
     WHERE ws1.ws_bill_customer_sk = tc.c_customer_sk) AS unique_order_count,
    (SELECT COALESCE(SUM(sr_return_amt_inc_tax), 0) 
     FROM store_returns sr 
     WHERE sr.sr_customer_sk = tc.c_customer_sk) AS total_return_amount
FROM TopCustomers tc
WHERE tc.rank <= 100
ORDER BY tc.total_spent DESC;
