
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_web_returns,
        SUM(wr_return_amt) AS total_refunded,
        SUM(wr_net_loss) AS total_loss
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
StoreReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_store_returns,
        SUM(sr_return_amt) AS total_refunded,
        SUM(sr_net_loss) AS total_loss
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(cwr.wr_returning_customer_sk, sr.sr_customer_sk) AS customer_sk,
        COALESCE(cwr.total_web_returns, 0) AS total_web_returns,
        COALESCE(cwr.total_refunded, 0) AS total_web_returned,
        COALESCE(cwr.total_loss, 0) AS total_web_loss,
        COALESCE(sr.total_store_returns, 0) AS total_store_returns,
        COALESCE(sr.total_refunded, 0) AS total_store_returned,
        COALESCE(sr.total_loss, 0) AS total_store_loss
    FROM 
        CustomerReturns cwr
    FULL OUTER JOIN 
        StoreReturns sr ON cwr.wr_returning_customer_sk = sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cr.total_web_returns,
    cr.total_web_returned,
    cr.total_web_loss,
    cr.total_store_returns,
    cr.total_store_returned,
    cr.total_store_loss
FROM 
    CombinedReturns cr
JOIN 
    customer c ON cr.customer_sk = c.c_customer_sk
WHERE 
    cr.total_web_returns > 0 OR cr.total_store_returns > 0
ORDER BY 
    cr.total_store_loss DESC, cr.total_web_loss DESC
LIMIT 50;
