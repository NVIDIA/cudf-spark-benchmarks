
WITH ProductReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt
    FROM web_returns
    GROUP BY wr_item_sk
),
StoreReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_store_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales_amt
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
Ranking AS (
    SELECT
        i.i_item_id,
        COALESCE(pr.total_web_returns, 0) AS web_returns,
        COALESCE(sr.total_store_returns, 0) AS store_returns,
        COALESCE(sd.total_web_sales, 0) AS web_sales,
        COALESCE(pr.total_web_return_amt, 0) AS web_return_amount,
        COALESCE(sr.total_store_return_amt, 0) AS store_return_amount,
        COALESCE(sd.total_web_sales_amt, 0) AS web_sales_amount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(sd.total_web_sales_amt, 0) DESC) AS sales_rank
    FROM item i
    LEFT JOIN ProductReturns pr ON i.i_item_sk = pr.wr_item_sk
    LEFT JOIN StoreReturns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT
    r.i_item_id,
    r.web_returns,
    r.store_returns,
    r.web_sales,
    r.web_sales_amount,
    r.web_return_amount,
    r.store_return_amount,
    r.sales_rank
FROM Ranking r
WHERE (r.web_sales > 0 OR r.store_returns > 0)
AND r.sales_rank <= 10
ORDER BY r.sales_rank;
