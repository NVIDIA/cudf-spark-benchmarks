
WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_item_sk) AS distinct_items_returned
    FROM store_returns
    GROUP BY sr_customer_sk
), 
ReturnDetails AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_web_returns,
        COUNT(DISTINCT wr_item_sk) AS distinct_web_items_returned
    FROM web_returns
    GROUP BY wr_returning_customer_sk
), 
CombinedReturns AS (
    SELECT 
        COALESCE(csr.sr_customer_sk, wrd.wr_returning_customer_sk) AS customer_sk,
        COALESCE(csr.total_returns, 0) AS total_store_returns,
        COALESCE(wrd.total_web_returns, 0) AS total_web_returns,
        (COALESCE(csr.total_returns, 0) + COALESCE(wrd.total_web_returns, 0)) AS total_overall_returns,
        (COALESCE(csr.distinct_items_returned, 0) + COALESCE(wrd.distinct_web_items_returned, 0)) AS total_distinct_items
    FROM CustomerReturns csr
    FULL OUTER JOIN ReturnDetails wrd ON csr.sr_customer_sk = wrd.wr_returning_customer_sk
), 
RankedReturns AS (
    SELECT 
        customer_sk,
        total_store_returns,
        total_web_returns,
        total_overall_returns,
        total_distinct_items,
        RANK() OVER (ORDER BY total_overall_returns DESC) AS overall_rank
    FROM CombinedReturns
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    cr.total_store_returns,
    cr.total_web_returns,
    cr.total_overall_returns,
    cr.total_distinct_items,
    CASE WHEN cr.total_overall_returns > 100 THEN 'High Returner'
         WHEN cr.total_overall_returns > 50 THEN 'Moderate Returner'
         ELSE 'Low Returner' END AS return_category
FROM RankedReturns cr
JOIN customer c ON cr.customer_sk = c.c_customer_sk
WHERE cr.total_distinct_items > 5
    AND (c.c_birth_year BETWEEN 1980 AND 1990 OR c.c_email_address LIKE '%@example.com')
ORDER BY cr.total_overall_returns DESC, c.c_last_name ASC
LIMIT 50;
