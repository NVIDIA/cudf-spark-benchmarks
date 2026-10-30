
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_web_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_web_returned_amt,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(cr.sr_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        COALESCE(wr.total_web_returned_quantity, 0) AS total_web_returned_quantity,
        COALESCE(wr.total_web_returned_amt, 0) AS total_web_returned_amt
    FROM CustomerReturns cr
    FULL OUTER JOIN WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
),
RankedReturns AS (
    SELECT 
        customer_sk,
        total_returned_quantity,
        total_returned_amt,
        total_web_returned_quantity,
        total_web_returned_amt,
        RANK() OVER (ORDER BY total_returned_amt DESC) AS rank_amt,
        RANK() OVER (ORDER BY total_returned_quantity DESC) AS rank_qty
    FROM CombinedReturns
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    r.total_returned_quantity,
    r.total_returned_amt,
    r.total_web_returned_quantity,
    r.total_web_returned_amt,
    r.rank_amt,
    '(High Value)' AS classification
FROM RankedReturns r
JOIN customer c ON r.customer_sk = c.c_customer_sk
WHERE (r.total_returned_amt > 1000 OR r.total_web_returned_amt > 1000)
AND r.rank_qty <= 10
AND (r.total_returned_quantity IS NOT NULL OR r.total_web_returned_quantity IS NOT NULL)
UNION ALL
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    r.total_returned_quantity,
    r.total_returned_amt,
    r.total_web_returned_quantity,
    r.total_web_returned_amt,
    r.rank_amt,
    '(Low Activity)' AS classification
FROM RankedReturns r
JOIN customer c ON r.customer_sk = c.c_customer_sk
WHERE r.rank_qty > 10
AND (r.total_returned_amt < 100 OR r.total_web_returned_amt < 100)
AND (r.total_returned_quantity IS NULL AND r.total_web_returned_quantity IS NULL)
ORDER BY classification, rank_amt;
