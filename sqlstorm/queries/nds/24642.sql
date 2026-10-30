
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        COUNT(*) OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank,
        SUM(sr_return_quantity) OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_quantity,
        SUM(sr_return_amt_inc_tax) OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt
    FROM store_returns
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
FinalData AS (
    SELECT 
        R.sr_item_sk,
        COALESCE(S.total_quantity, 0) AS total_sales_quantity,
        COALESCE(S.total_profit, 0) AS total_sales_profit,
        COALESCE(R.cumulative_return_quantity, 0) AS total_return_quantity,
        COALESCE(R.cumulative_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(R.cumulative_return_amt, 0) > 0 
            THEN (COALESCE(S.total_profit, 0) / NULLIF(COALESCE(R.cumulative_return_amt, 0), 0)) 
            ELSE NULL 
        END AS profit_per_return_amount
    FROM RankedReturns R
    LEFT JOIN SalesData S ON R.sr_item_sk = S.ws_item_sk
    WHERE R.return_rank = 1 OR S.item_rank <= 10
)
SELECT 
    fd.sr_item_sk,
    fd.total_sales_quantity,
    fd.total_sales_profit,
    fd.total_return_quantity,
    fd.total_return_amt,
    fd.profit_per_return_amount
FROM FinalData fd
WHERE fd.total_return_quantity > (SELECT AVG(cumulative_return_quantity) FROM RankedReturns) 
    OR fd.total_sales_quantity IS NULL
ORDER BY fd.profit_per_return_amount DESC NULLS LAST
LIMIT 50;
