
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
        COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(cr.cr_return_amount) AS total_catalog_return_amt,
        SUM(wr.wr_return_amt) AS total_web_return_amt
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk
),
ReturnStatistics AS (
    SELECT
        total_store_returns,
        total_catalog_returns,
        total_web_returns,
        total_return_amt,
        total_catalog_return_amt,
        total_web_return_amt,
        (total_return_amt + total_catalog_return_amt + total_web_return_amt) AS total_returned_amount,
        (total_store_returns + total_catalog_returns + total_web_returns) AS total_returns_count,
        CASE 
            WHEN (total_store_returns + total_catalog_returns + total_web_returns) = 0 THEN 0
            ELSE (total_returned_amount / NULLIF(total_returns_count, 0)) 
        END AS average_return_per_order
    FROM CustomerSummary
),
OverallStatistics AS (
    SELECT
        SUM(total_store_returns) AS sum_total_store_returns,
        SUM(total_catalog_returns) AS sum_total_catalog_returns,
        SUM(total_web_returns) AS sum_total_web_returns,
        SUM(total_returned_amount) AS sum_total_returned_amount,
        AVG(average_return_per_order) AS average_return_per_order
    FROM ReturnStatistics
)
SELECT 
    o.sum_total_store_returns,
    o.sum_total_catalog_returns,
    o.sum_total_web_returns,
    o.sum_total_returned_amount,
    o.average_return_per_order
FROM OverallStatistics o
JOIN (
    SELECT 
        COUNT(DISTINCT c.c_customer_sk) AS total_customers 
    FROM customer c
) AS total_customers ON TRUE
WHERE o.sum_total_returned_amount > 0
ORDER BY o.average_return_per_order DESC;
