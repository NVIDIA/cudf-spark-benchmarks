
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
),
StoreReturns AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(sr.sr_return_amt) AS store_return_amt
    FROM
        store_returns sr
    GROUP BY
        sr.sr_item_sk
),
TotalReturns AS (
    SELECT
        COALESCE(cr.wr_item_sk, sr.sr_item_sk) AS item_sk,
        COALESCE(cr.total_return_qty, 0) + COALESCE(sr.store_return_qty, 0) AS total_return_qty,
        COALESCE(cr.total_return_amt, 0) + COALESCE(sr.store_return_amt, 0) AS total_return_amt
    FROM
        CustomerReturns cr
    FULL OUTER JOIN
        StoreReturns sr ON cr.wr_item_sk = sr.sr_item_sk
)
SELECT
    rs.ws_item_sk,
    rs.ws_order_number,
    rs.ws_sales_price,
    rs.ws_net_profit,
    tr.total_return_qty,
    tr.total_return_amt,
    CASE
        WHEN tr.total_return_qty IS NOT NULL AND tr.total_return_qty > 0 THEN 'Item Returned'
        ELSE 'No Returns'
    END AS return_status
FROM
    RankedSales rs
LEFT JOIN
    TotalReturns tr ON rs.ws_item_sk = tr.item_sk
WHERE
    rs.sales_rank = 1
    AND rs.ws_net_profit > 100
ORDER BY
    rs.ws_item_sk, rs.ws_order_number;
