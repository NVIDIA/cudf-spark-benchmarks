
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_quantity) AS total_returned_quantity_web,
        SUM(wr_return_amt) AS total_return_amount_web
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        COALESCE(cr.total_store_returns, 0) AS total_store_returns,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        (COALESCE(cr.total_returned_quantity, 0) + COALESCE(wr.total_returned_quantity_web, 0)) AS total_returned_quantity,
        (COALESCE(cr.total_return_amount, 0) + COALESCE(wr.total_return_amount_web, 0)) AS total_return_amount
    FROM CustomerReturns cr
    FULL OUTER JOIN WebReturns wr ON cr.c_customer_sk = wr.wr_returning_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(r.total_store_returns, 0) AS Store_Returns,
    COALESCE(r.total_web_returns, 0) AS Web_Returns,
    r.total_returned_quantity,
    r.total_return_amount
FROM CombinedReturns r
JOIN customer c ON r.c_customer_sk = c.c_customer_sk
WHERE r.total_return_amount > 100
ORDER BY r.total_return_amount DESC
LIMIT 10;
