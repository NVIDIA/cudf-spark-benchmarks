
WITH CustomerOrderSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spend_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cus.c_customer_sk,
        cus.c_first_name,
        cus.c_last_name,
        cus.total_spent,
        cus.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM CustomerOrderSummary cus
    JOIN customer_demographics cd ON cus.c_customer_sk = cd.cd_demo_sk
    WHERE cus.spend_rank <= 10
),
ReturnSummary AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.return_count, 0) AS return_count,
    CASE 
        WHEN tc.total_spent > 1000 THEN 'High Value'
        WHEN tc.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM TopCustomers tc
LEFT JOIN ReturnSummary rs ON tc.c_customer_sk = rs.sr_customer_sk
ORDER BY tc.total_spent DESC
LIMIT 20;
