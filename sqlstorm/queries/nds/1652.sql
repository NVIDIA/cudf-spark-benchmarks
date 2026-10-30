
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_spending,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spending,
        cs.total_purchases,
        DENSE_RANK() OVER (ORDER BY cs.total_spending DESC) AS spending_rank
    FROM CustomerSales cs
    WHERE cs.total_spending IS NOT NULL
),
RecentReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
ReturnCustomers AS (
    SELECT 
        rc.sr_customer_sk,
        rc.total_returned,
        rc.return_count
    FROM RecentReturns rc
    WHERE rc.return_count > 3
),
FinalReport AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_spending,
        COALESCE(rc.total_returned, 0) AS total_returned,
        hvc.spending_rank
    FROM HighValueCustomers hvc
    LEFT JOIN ReturnCustomers rc ON hvc.c_customer_sk = rc.sr_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_spending,
    f.total_returned,
    f.spending_rank,
    CASE 
        WHEN f.total_returned > 0 THEN 'YES' 
        ELSE 'NO' 
    END AS has_returned,
    CONCAT('Customer: ', f.c_first_name, ' ', f.c_last_name, ' has spent a total of $', 
           ROUND(f.total_spending, 2), ' with a return amount of $', ROUND(f.total_returned, 2)) AS customer_summary
FROM FinalReport f
WHERE f.spending_rank <= 10
ORDER BY f.total_spending DESC;
