
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 20000101 AND 20001231
),
CustomerReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_return_amt
    FROM
        web_returns
    WHERE
        wr_returned_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY
        wr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.ws_quantity, 0) AS total_sold_quantity,
    COALESCE(rs.ws_net_profit, 0) AS total_net_profit,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    (COALESCE(rs.ws_net_profit, 0) - COALESCE(cr.total_return_amt, 0)) AS net_profit_after_returns,
    CASE
        WHEN (COALESCE(rs.ws_net_profit, 0) - COALESCE(cr.total_return_amt, 0)) < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_loss_status
FROM
    item i
LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rn = 1
LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE
    i.i_current_price > 0
ORDER BY
    net_profit_after_returns DESC
LIMIT 10;
