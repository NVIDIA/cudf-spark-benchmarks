
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM store_returns
    GROUP BY sr_item_sk
),
TopReturnedItems AS (
    SELECT
        item.i_item_sk,
        item.i_item_desc,
        COALESCE(rr.total_returns, 0) AS total_returns,
        COALESCE(rr.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(rr.total_returned_amt, 0.00) AS total_returned_amt,
        CASE
            WHEN COALESCE(rr.total_returns, 0) = 0 THEN 'No Returns'
            WHEN rr.return_rank = 1 THEN 'Top Returned'
            ELSE 'Regular Returner'
        END AS return_category
    FROM item
    LEFT JOIN RankedReturns rr ON item.i_item_sk = rr.sr_item_sk
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales_amt
    FROM web_sales
    GROUP BY ws_item_sk
),
FinalMetrics AS (
    SELECT
        tri.i_item_sk,
        tri.i_item_desc,
        tri.total_returns,
        tri.total_returned_qty,
        tri.total_returned_amt,
        COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(sd.total_sales_amt, 0.00) AS total_sales_amt,
        (tri.total_returned_amt / NULLIF(sd.total_sales_amt, 0)) * 100 AS return_percentage
    FROM TopReturnedItems tri
    LEFT JOIN SalesData sd ON tri.i_item_sk = sd.ws_item_sk
)
SELECT
    f.i_item_sk,
    f.i_item_desc,
    f.total_returns,
    f.total_returned_qty,
    f.total_returned_amt,
    f.total_sales_quantity,
    f.total_sales_amt,
    f.return_percentage,
    (CASE
        WHEN f.return_percentage > 50 THEN 'High Risk'
        WHEN f.return_percentage BETWEEN 10 AND 50 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END) AS risk_category
FROM FinalMetrics f
WHERE f.total_sales_quantity > (
    SELECT AVG(total_sales_quantity) FROM SalesData
) 
AND f.return_percentage IS NOT NULL
ORDER BY risk_category DESC, return_percentage DESC;
