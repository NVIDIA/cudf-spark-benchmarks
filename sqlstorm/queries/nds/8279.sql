
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
StoreReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
ReturnComparison AS (
    SELECT 
        coalesce(cr.wr_returning_customer_sk, sr.sr_customer_sk) AS customer_sk,
        COALESCE(cr.total_returned_quantity, 0) AS web_return_qty,
        COALESCE(sr.total_returned_quantity, 0) AS store_return_qty,
        COALESCE(cr.total_returned_amt, 0) AS web_return_amt,
        COALESCE(sr.total_returned_amt, 0) AS store_return_amt
    FROM CustomerReturns cr
    FULL OUTER JOIN StoreReturns sr ON cr.wr_returning_customer_sk = sr.sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.web_return_qty,
        r.store_return_qty,
        r.web_return_amt,
        r.store_return_amt,
        (r.web_return_amt + r.store_return_amt) AS total_return_amt
    FROM ReturnComparison r
    JOIN customer c ON c.c_customer_sk = r.customer_sk
    WHERE r.web_return_amt + r.store_return_amt > 500
)

SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.web_return_qty,
    hvc.store_return_qty,
    hvc.total_return_amt,
    CASE 
        WHEN hvc.web_return_qty > hvc.store_return_qty THEN 'More returns from web'
        WHEN hvc.web_return_qty < hvc.store_return_qty THEN 'More returns from store'
        ELSE 'Equal returns'
    END AS return_type
FROM HighValueCustomers hvc
ORDER BY hvc.total_return_amt DESC
LIMIT 100;
