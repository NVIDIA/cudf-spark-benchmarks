
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_value,
        AVG(sr_return_amt_inc_tax) AS avg_return_value
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
WebReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        COUNT(wr_order_number) AS total_web_returns,
        SUM(wr_return_quantity) AS total_web_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_web_returned_value,
        AVG(wr_return_amt_inc_tax) AS avg_web_return_value
    FROM web_returns
    GROUP BY wr_returned_date_sk, wr_item_sk
),
TotalReturns AS (
    SELECT 
        COALESCE(cr.sr_returned_date_sk, wr.wr_returned_date_sk) AS return_date,
        COALESCE(cr.sr_item_sk, wr.wr_item_sk) AS item_sk,
        COALESCE(cr.total_returns, 0) + COALESCE(wr.total_web_returns, 0) AS total_returns,
        COALESCE(cr.total_returned_quantity, 0) + COALESCE(wr.total_web_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_value, 0) + COALESCE(wr.total_web_returned_value, 0) AS total_returned_value,
        COALESCE(cr.avg_return_value, 0) AS avg_store_return_value,
        COALESCE(wr.avg_web_return_value, 0) AS avg_web_return_value
    FROM CustomerReturns cr
    FULL OUTER JOIN WebReturns wr ON cr.sr_returned_date_sk = wr.wr_returned_date_sk AND cr.sr_item_sk = wr.wr_item_sk
),
FinalMetrics AS (
    SELECT 
        return_date,
        item_sk,
        total_returns,
        total_returned_quantity,
        total_returned_value,
        CASE WHEN total_returns > 0 THEN total_returned_value / total_returns ELSE 0 END AS avg_return_value,
        (avg_store_return_value + avg_web_return_value) / 2 AS combined_avg_return_value
    FROM TotalReturns
)
SELECT 
    d.d_date AS return_date,
    f.item_sk,
    f.total_returns,
    f.total_returned_quantity,
    f.total_returned_value,
    f.avg_return_value,
    f.combined_avg_return_value,
    i.i_item_desc
FROM FinalMetrics f
JOIN date_dim d ON d.d_date_sk = f.return_date
JOIN item i ON i.i_item_sk = f.item_sk
WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY return_date, f.item_sk;
