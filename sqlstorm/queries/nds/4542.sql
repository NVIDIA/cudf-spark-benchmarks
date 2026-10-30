
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT wr_order_number) AS web_return_count,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt
    FROM 
        customer c
    JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        SUM(sr_return_amt_inc_tax) AS total_store_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CombinedReturns AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        COALESCE(cr.web_return_count, 0) AS web_return_count,
        COALESCE(sr.store_return_count, 0) AS store_return_count,
        (COALESCE(cr.total_web_return_amt, 0) + COALESCE(sr.total_store_return_amt, 0)) AS total_return_amt
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        StoreReturns sr ON cr.c_customer_sk = sr.sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.web_return_count,
        cr.store_return_count,
        cr.total_return_amt,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amt DESC) AS return_rank
    FROM 
        CombinedReturns cr
    JOIN 
        customer c ON cr.c_customer_sk = c.c_customer_sk
    WHERE 
        cr.total_return_amt > (SELECT AVG(total_return_amt) FROM CombinedReturns)
)
SELECT 
    hrc.c_customer_id,
    hrc.c_first_name,
    hrc.c_last_name,
    hrc.web_return_count,
    hrc.store_return_count,
    hrc.total_return_amt,
    CASE 
        WHEN hrc.total_return_amt IS NULL THEN 'No Returns'
        WHEN hrc.total_return_amt >= 1000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS return_category
FROM 
    HighReturnCustomers hrc
WHERE 
    hrc.return_rank <= 10
ORDER BY 
    hrc.total_return_amt DESC;
