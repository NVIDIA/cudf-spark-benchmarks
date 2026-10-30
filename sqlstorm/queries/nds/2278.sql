
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS web_return_count,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
ReturnStatistics AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        COALESCE(wr.web_return_count, 0) AS total_web_return_count,
        COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt,
        (COALESCE(cr.total_returned_amt, 0) + COALESCE(wr.total_web_return_amt, 0)) AS overall_return_amt
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebReturns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
)
SELECT 
    r.c_customer_id,
    r.total_returned,
    r.total_returned_amt,
    r.total_web_return_count,
    r.total_web_return_amt,
    r.overall_return_amt,
    DENSE_RANK() OVER (ORDER BY r.overall_return_amt DESC) AS return_rank
FROM 
    ReturnStatistics r
WHERE 
    r.total_returned > 0 OR r.total_web_return_count > 0
ORDER BY 
    r.overall_return_amt DESC
LIMIT 10;
