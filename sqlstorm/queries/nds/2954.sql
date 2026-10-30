WITH CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        co.order_count,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS spend_rank
    FROM CustomerOrders co
    WHERE co.total_spent > 1000
),
RecentReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk >= 
          (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = cast('2002-10-01' as date) - INTERVAL '30 days')
    GROUP BY sr.sr_customer_sk
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.order_count,
    hs.total_spent,
    COALESCE(rr.total_returned, 0) AS total_returned,
    COALESCE(rr.return_count, 0) AS return_count,
    (hs.total_spent - COALESCE(rr.total_returned, 0)) AS net_spending
FROM HighSpenders hs
LEFT JOIN RecentReturns rr ON hs.c_customer_sk = rr.sr_customer_sk
WHERE hs.spend_rank <= 100
ORDER BY net_spending DESC;