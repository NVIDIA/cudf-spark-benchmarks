WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date))
),
HighProfitItems AS (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM
        RankedSales rs
    WHERE
        rs.rank <= 10
    GROUP BY
        rs.ws_item_sk
),
RecentReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        store_returns
    WHERE
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY
        sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    hi.total_net_profit,
    COALESCE(rr.total_returned, 0) AS total_returned,
    COALESCE(rr.total_return_amount, 0.00) AS total_return_amount,
    (hi.total_net_profit - COALESCE(rr.total_return_amount, 0)) AS adjusted_net_profit
FROM
    item i
LEFT JOIN HighProfitItems hi ON i.i_item_sk = hi.ws_item_sk
LEFT JOIN RecentReturns rr ON i.i_item_sk = rr.sr_item_sk
WHERE
    i.i_current_price IS NOT NULL
    AND (hi.total_net_profit > 10000 OR rr.total_returned > 5)
ORDER BY
    adjusted_net_profit DESC
LIMIT 20;