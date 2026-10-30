
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebReturns AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_quantity) AS total_web_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_web_returned_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT
        COALESCE(c.c_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown') AS customer_name,
        COALESCE(cr.total_returns, 0) AS store_returns,
        COALESCE(wr.total_web_returns, 0) AS web_returns,
        COALESCE(cr.total_returned_quantity, 0) + COALESCE(wr.total_web_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amt, 0) + COALESCE(wr.total_web_returned_amt, 0) AS total_returned_amt
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    FULL OUTER JOIN WebReturns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    WHERE COALESCE(cr.total_returns, 0) > 0 OR COALESCE(wr.total_web_returns, 0) > 0
),
RankedReturns AS (
    SELECT
        customer_sk,
        customer_name,
        store_returns,
        web_returns,
        total_returned_quantity,
        total_returned_amt,
        RANK() OVER (ORDER BY total_returned_amt DESC) AS return_rank
    FROM CombinedReturns
)
SELECT
    customer_sk,
    customer_name,
    store_returns,
    web_returns,
    total_returned_quantity,
    total_returned_amt,
    CASE
        WHEN return_rank = 1 THEN 'Top Returner'
        WHEN return_rank BETWEEN 2 AND 5 THEN 'Top 5 Returners'
        ELSE 'Regular Returner'
    END AS returner_category
FROM RankedReturns
WHERE total_returned_amt IS NOT NULL
  AND (store_returns > 1 OR web_returns > 1)
ORDER BY total_returned_amt DESC, customer_name
LIMIT 10;
