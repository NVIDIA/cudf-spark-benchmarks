WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank,
        SUM(ws_net_paid) OVER (PARTITION BY ws_item_sk) AS total_net_paid
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2452020 AND 2452365 
),
CustomerReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amt
    FROM
        web_returns
    WHERE
        wr_returned_date_sk BETWEEN 2452020 AND 2452365 
    GROUP BY
        wr_item_sk
),
SaleReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS return_count,
        SUM(sr_return_amt) AS return_amount
    FROM
        store_returns
    WHERE
        sr_returned_date_sk BETWEEN 2452020 AND 2452365 
    GROUP BY
        sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_net_paid, 0) AS total_web_sales,
    COALESCE(c.total_return_quantity, 0) AS total_web_returns,
    COALESCE(str.return_count, 0) AS total_store_returns,
    (COALESCE(s.total_net_paid, 0) - COALESCE(c.total_return_amt, 0) - COALESCE(str.return_amount, 0)) AS net_profit
FROM
    item i
LEFT JOIN
    RankedSales s ON i.i_item_sk = s.ws_item_sk AND s.rank = 1
LEFT JOIN
    CustomerReturns c ON i.i_item_sk = c.wr_item_sk
LEFT JOIN
    SaleReturns str ON i.i_item_sk = str.sr_item_sk
WHERE
    (COALESCE(s.total_net_paid, 0) - COALESCE(c.total_return_amt, 0) - COALESCE(str.return_amount, 0)) > 1000
ORDER BY
    net_profit DESC
LIMIT 10;