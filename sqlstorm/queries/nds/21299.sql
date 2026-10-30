
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_return_quantity) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_return_tax) AS total_web_return_tax,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt_inc_tax
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
TotalReturns AS (
    SELECT 
        COALESCE(cr.sr_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(cr.total_returns, 0) AS total_store_returns,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(cr.total_return_amt, 0) + COALESCE(wr.total_web_return_amt, 0) AS combined_return_amt,
        COALESCE(cr.total_return_tax, 0) + COALESCE(wr.total_web_return_tax, 0) AS combined_return_tax,
        COALESCE(cr.total_return_amt_inc_tax, 0) + COALESCE(wr.total_web_return_amt_inc_tax, 0) AS combined_return_amt_inc_tax
    FROM CustomerReturns cr
    FULL OUTER JOIN WebReturns wr 
        ON cr.sr_customer_sk = wr.wr_returning_customer_sk
),
RankedReturns AS (
    SELECT 
        customer_sk,
        total_store_returns,
        total_web_returns,
        combined_return_amt,
        combined_return_tax,
        combined_return_amt_inc_tax,
        RANK() OVER (ORDER BY combined_return_amt DESC) AS return_rank
    FROM TotalReturns
    WHERE combined_return_amt > 100
),
HighReturnCustomers AS (
    SELECT 
        customer_sk,
        total_store_returns,
        total_web_returns,
        combined_return_amt,
        combined_return_tax,
        combined_return_amt_inc_tax,
        LAG(combined_return_amt) OVER (ORDER BY return_rank) AS previous_return_amt
    FROM RankedReturns
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hr.total_store_returns,
    hr.total_web_returns,
    hr.combined_return_amt,
    hr.combined_return_tax,
    hr.combined_return_amt_inc_tax,
    CASE
        WHEN hr.previous_return_amt IS NULL THEN 'First Time High Return'
        WHEN hr.combined_return_amt > hr.previous_return_amt THEN 'Increased'
        WHEN hr.combined_return_amt < hr.previous_return_amt THEN 'Decreased'
        ELSE 'No Change'
    END AS return_trend
FROM HighReturnCustomers hr
JOIN customer c ON hr.customer_sk = c.c_customer_sk
WHERE (c.c_first_name IS NOT NULL OR c.c_last_name IS NOT NULL)
    AND (c.c_birth_month BETWEEN 1 AND 12 OR c.c_birth_month IS NULL)
ORDER BY hr.combined_return_amt DESC;
