WITH CustomerSales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_net_paid) AS total_spent,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT cs.c_customer_sk,
           cs.c_first_name,
           cs.c_last_name,
           cs.total_spent,
           cs.order_count,
           RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM CustomerSales cs
    WHERE cs.order_count > 5
),
RecentReturns AS (
    SELECT sr.sr_customer_sk,
           SUM(sr.sr_return_amt_inc_tax) AS total_returned
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_date >= (cast('2002-10-01' as date) - INTERVAL '30 days')
    )
    GROUP BY sr.sr_customer_sk
)
SELECT hs.c_customer_sk,
       hs.c_first_name,
       hs.c_last_name,
       hs.total_spent,
       hs.order_count,
       COALESCE(rr.total_returned, 0) AS total_returned,
       CASE 
           WHEN rr.total_returned IS NOT NULL THEN 'Has Returns'
           ELSE 'No Returns'
       END AS return_status
FROM HighSpenders hs
LEFT JOIN RecentReturns rr ON hs.c_customer_sk = rr.sr_customer_sk
WHERE hs.spend_rank <= 10
ORDER BY hs.total_spent DESC;