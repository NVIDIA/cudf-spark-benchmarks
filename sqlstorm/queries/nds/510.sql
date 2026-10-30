
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_transactions,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM CustomerSales cs
),
StoreReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
ReturnImpact AS (
    SELECT 
        sr.sr_customer_sk,
        CASE
            WHEN sr.total_returns IS NULL THEN 'No Returns'
            WHEN sr.total_returns > 0 THEN 'Returns Made'
            ELSE 'Positive Impact'
        END AS return_status
    FROM StoreReturns sr
)
SELECT 
    sr.c_first_name,
    sr.c_last_name,
    sr.total_spent,
    sr.total_transactions,
    CASE 
        WHEN ri.return_status = 'Returns Made' THEN 'High Risk Customer'
        ELSE 'Low Risk Customer'
    END AS customer_risk
FROM SalesRanked sr
LEFT JOIN ReturnImpact ri ON sr.c_customer_sk = ri.sr_customer_sk
WHERE sr.sales_rank <= 100
ORDER BY sr.total_spent DESC;
