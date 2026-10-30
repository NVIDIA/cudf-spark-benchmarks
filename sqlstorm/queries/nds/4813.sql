
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM
        web_sales
),
TotalReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(tr.total_returned, 0) AS total_returned,
        COALESCE(rs.ws_net_profit, 0) AS total_net_profit
    FROM
        item i
    LEFT JOIN TotalReturns tr ON i.i_item_sk = tr.wr_item_sk
    LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rn = 1
)
SELECT
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    CASE 
        WHEN id.total_returned > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CASE 
        WHEN id.total_net_profit IS NULL THEN 'No Profit Data'
        ELSE CAST(id.total_net_profit AS STRING)
    END AS net_profit_status
FROM
    ItemDetails id
WHERE
    id.i_current_price > (SELECT AVG(i_current_price) FROM item)
ORDER BY
    id.total_net_profit DESC NULLS LAST;
