
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amount,
        SUM(wr_return_quantity) AS total_web_return_quantity
    FROM web_returns
    GROUP BY wr_returning_customer_sk
), StoreReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_store_return_amount,
        SUM(sr_return_quantity) AS total_store_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
), CombinedReturns AS (
    SELECT 
        COALESCE(wr.wr_returning_customer_sk, sr.sr_customer_sk) AS customer_sk,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(sr.total_store_returns, 0) AS total_store_returns,
        (COALESCE(wr.total_web_return_amount, 0) + COALESCE(sr.total_store_return_amount, 0)) AS total_return_amount,
        (COALESCE(wr.total_web_return_quantity, 0) + COALESCE(sr.total_store_return_quantity, 0)) AS total_return_quantity
    FROM CustomerReturns wr
    FULL OUTER JOIN StoreReturns sr ON wr.wr_returning_customer_sk = sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_web_returns, 0) as web_return_count,
    COALESCE(cr.total_store_returns, 0) as store_return_count,
    cr.total_return_amount,
    cr.total_return_quantity,
    (
        SELECT AVG(total_return_quantity) 
        FROM CombinedReturns 
        WHERE total_return_quantity > 0
    ) AS average_non_zero_return_quantity,
    DENSE_RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
FROM customer c
LEFT JOIN CombinedReturns cr ON c.c_customer_sk = cr.customer_sk
WHERE (cr.total_return_amount IS NOT NULL AND cr.total_return_amount > 100) 
OR c.c_birth_year < 1990
ORDER BY return_rank, c.c_last_name;
