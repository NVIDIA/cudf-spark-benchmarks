
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count
    FROM CustomerSales cs
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
),
RecentReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned,
        COUNT(wr.wr_order_number) AS return_count
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY wr.wr_returning_customer_sk
),
ReturnRate AS (
    SELECT 
        hs.c_customer_sk,
        hs.total_spent,
        COALESCE(rr.total_returned, 0) AS total_returned,
        COALESCE(rr.return_count, 0) AS return_count,
        CASE WHEN hs.total_spent > 0 THEN (COALESCE(rr.total_returned, 0) / hs.total_spent) * 100 ELSE 0 END AS return_rate
    FROM HighSpenders hs
    LEFT JOIN RecentReturns rr ON hs.c_customer_sk = rr.wr_returning_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.total_spent,
    r.total_returned,
    r.return_count,
    r.return_rate,
    CASE 
        WHEN r.return_rate > 10 THEN 'High Risk'
        WHEN r.return_rate BETWEEN 5 AND 10 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM ReturnRate r
ORDER BY r.return_rate DESC;
