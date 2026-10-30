
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers
    FROM RankedReturns
    WHERE rn <= 5
    GROUP BY sr_item_sk
),
WebAggregatedReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_web_returned,
        COUNT(DISTINCT wr_returning_customer_sk) AS distinct_web_customers
    FROM web_returns
    WHERE wr_return_quantity IS NOT NULL
    GROUP BY wr_item_sk
),
CombinedReturns AS (
    SELECT 
        a.sr_item_sk,
        COALESCE(a.total_returned, 0) AS total_returned,
        COALESCE(b.total_web_returned, 0) AS total_web_returned,
        (COALESCE(a.total_returned, 0) + COALESCE(b.total_web_returned, 0)) AS combined_returned,
        (COALESCE(a.distinct_customers, 0) + COALESCE(b.distinct_web_customers, 0)) AS total_distinct_customers
    FROM AggregatedReturns a
    FULL OUTER JOIN WebAggregatedReturns b ON a.sr_item_sk = b.wr_item_sk
)
SELECT 
    c.i_item_id,
    c.i_item_desc,
    r.total_returned,
    r.total_web_returned,
    r.combined_returned,
    r.total_distinct_customers,
    CASE 
        WHEN r.combined_returned > 100 THEN 'High Return'
        WHEN r.combined_returned BETWEEN 50 AND 100 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category,
    CASE 
        WHEN r.total_distinct_customers = 0 THEN NULL 
        ELSE r.combined_returned / r.total_distinct_customers 
    END AS avg_return_per_customer
FROM item c
LEFT JOIN CombinedReturns r ON c.i_item_sk = r.sr_item_sk
WHERE (r.total_returned IS NOT NULL OR r.total_web_returned IS NOT NULL)
AND (c.i_current_price >= (SELECT AVG(i_current_price * 1.1) FROM item) OR c.i_item_desc LIKE '%sale%')
ORDER BY r.combined_returned DESC
LIMIT 10;
