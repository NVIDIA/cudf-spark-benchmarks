
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS web_returns_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amt_inc_tax,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amt_inc_tax
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id
),
ReturnStats AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cr.web_returns_count,
        cr.total_web_return_amt_inc_tax,
        cr.store_returns_count,
        cr.total_store_return_amt_inc_tax,
        COALESCE(cr.web_returns_count, 0) + COALESCE(cr.store_returns_count, 0) AS total_returns,
        CASE 
            WHEN COALESCE(cr.web_returns_count, 0) + COALESCE(cr.store_returns_count, 0) = 0 THEN 'No Returns'
            WHEN COALESCE(cr.total_web_return_amt_inc_tax, 0) > COALESCE(cr.total_store_return_amt_inc_tax, 0) THEN 'More Web Returns'
            ELSE 'More Store Returns'
        END AS return_type
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_id = cr.c_customer_id
),
RankedReturns AS (
    SELECT 
        rs.*, 
        RANK() OVER (ORDER BY total_returns DESC) AS return_rank
    FROM ReturnStats rs
)
SELECT 
    r.customer_id,
    r.web_returns_count,
    r.total_web_return_amt_inc_tax,
    r.store_returns_count,
    r.total_store_return_amt_inc_tax,
    r.total_returns,
    r.return_type,
    CASE 
        WHEN r.return_type = 'More Web Returns' AND r.total_returns > 0 THEN 'Web Dominance'
        WHEN r.return_type = 'More Store Returns' AND r.total_returns > 0 THEN 'Store Dominance'
        ELSE 'No Dominance'
    END AS dominance_status
FROM RankedReturns r
WHERE r.return_rank <= 10
ORDER BY r.total_returns DESC;
