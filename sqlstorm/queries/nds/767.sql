
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(wr_return_tax) AS total_web_return_tax,
        AVG(wr_return_quantity) AS avg_web_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(cr.sr_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        COALESCE(cr.avg_return_quantity, 0) AS avg_return_quantity,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(wr.total_web_return_amount, 0) AS total_web_return_amount,
        COALESCE(wr.total_web_return_tax, 0) AS total_web_return_tax,
        COALESCE(wr.avg_web_return_quantity, 0) AS avg_web_return_quantity
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
),
FinalReturns AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        returns.total_returns,
        returns.total_return_amount,
        returns.total_return_tax,
        returns.avg_return_quantity,
        returns.total_web_returns,
        returns.total_web_return_amount,
        returns.total_web_return_tax,
        returns.avg_web_return_quantity,
        DENSE_RANK() OVER (ORDER BY returns.total_return_amount DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        CombinedReturns returns ON c.c_customer_sk = returns.customer_sk
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.total_returns,
    f.total_return_amount,
    f.total_return_tax,
    f.avg_return_quantity,
    f.total_web_returns,
    f.total_web_return_amount,
    f.total_web_return_tax,
    f.avg_web_return_quantity
FROM 
    FinalReturns f
WHERE 
    f.rank <= 10
ORDER BY 
    f.total_return_amount DESC;
