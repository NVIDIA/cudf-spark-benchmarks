
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_amt DESC) as rn
    FROM store_returns
),
TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(tr.total_sales, 0) AS total_sales,
        COALESCE(rr.return_amt, 0) AS total_returns
    FROM customer c
    LEFT JOIN TotalSales tr ON c.c_customer_sk = tr.ws_bill_customer_sk
    LEFT JOIN (
        SELECT sr_customer_sk, SUM(sr_return_amt) AS return_amt
        FROM RankedReturns
        WHERE rn <= 5
        GROUP BY sr_customer_sk
    ) rr ON c.c_customer_sk = rr.sr_customer_sk
    WHERE c.c_birth_year IS NOT NULL
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_returns,
    (tc.total_sales - tc.total_returns) AS net_sales,
    CASE 
        WHEN tc.total_sales > 5000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM TopCustomers tc
WHERE COALESCE(tc.total_sales, 0) > 0
ORDER BY net_sales DESC
LIMIT 10;
