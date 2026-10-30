
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ItemRank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS TotalSold
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_rec_start_date <= DATE '2002-10-01' AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > DATE '2002-10-01')
),
HighValueReturns AS (
    SELECT
        sr.sr_item_sk,
        COUNT(sr.sr_return_quantity) AS ReturnCount,
        SUM(sr.sr_return_amt_inc_tax) AS TotalReturnAmt
    FROM
        store_returns sr
    WHERE
        sr.sr_return_quantity > 0
    GROUP BY
        sr.sr_item_sk
    HAVING
        SUM(sr.sr_return_amt_inc_tax) > 1000
),
SalesAnalysis AS (
    SELECT
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_sales_price,
        r.ws_ext_sales_price,
        COALESCE(hvr.ReturnCount, 0) AS HighValueReturnCount,
        COALESCE(hvr.TotalReturnAmt, 0) AS HighValueTotalReturnAmt
    FROM
        RankedSales r
    LEFT JOIN
        HighValueReturns hvr ON r.ws_item_sk = hvr.sr_item_sk
)
SELECT
    sa.ws_order_number,
    sa.ws_item_sk,
    sa.ws_sales_price,
    sa.ws_ext_sales_price,
    sa.HighValueReturnCount,
    sa.HighValueTotalReturnAmt,
    CASE
        WHEN sa.HighValueTotalReturnAmt > 1000 THEN 'Significant Return'
        WHEN sa.HighValueTotalReturnAmt IS NULL THEN 'No Returns'
        ELSE 'Normal Return'
    END AS ReturnStatus,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk)
     FROM web_sales
     WHERE ws_item_sk = sa.ws_item_sk
     AND ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31')
    ) AS DistinctCustomers
FROM
    SalesAnalysis sa
WHERE
    sa.HighValueReturnCount > 0 OR sa.HighValueTotalReturnAmt IS NOT NULL
ORDER BY
    sa.ws_item_sk, sa.ws_order_number
LIMIT 100;
