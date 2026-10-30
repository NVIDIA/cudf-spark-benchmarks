
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS rank 
    FROM web_returns 
    GROUP BY wr_returning_customer_sk
),
HighReturners AS (
    SELECT 
        r.wr_returning_customer_sk AS returning_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        r.return_count,
        r.total_return_amount
    FROM RankedReturns r
    JOIN customer c ON r.wr_returning_customer_sk = c.c_customer_sk
    WHERE r.rank <= 10
),
AverageSales AS (
    SELECT 
        w.ws_bill_customer_sk, 
        AVG(w.ws_net_paid) AS avg_net_paid
    FROM web_sales w 
    GROUP BY w.ws_bill_customer_sk
),
CustomerWithReturns AS (
    SELECT 
        hr.returning_customer_sk,
        hr.return_count,
        hr.total_return_amount,
        COALESCE(avg.avg_net_paid, 0) AS avg_net_paid
    FROM HighReturners hr
    LEFT JOIN AverageSales avg ON hr.returning_customer_sk = avg.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cr.return_count,
    cr.total_return_amount,
    cr.avg_net_paid,
    CASE 
        WHEN cr.total_return_amount > cr.avg_net_paid THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_category
FROM CustomerWithReturns cr
JOIN customer c ON cr.returning_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE cr.total_return_amount IS NOT NULL
ORDER BY cr.total_return_amount DESC;
