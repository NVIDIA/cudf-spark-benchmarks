WITH RankedSales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001 AND d_moy IN (SELECT DISTINCT d_moy FROM date_dim WHERE d_holiday = 'Y')
    )
), FilteredReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN RankedSales rs ON cr.cr_item_sk = rs.ws_item_sk
    WHERE rs.profit_rank = 1
    GROUP BY cr.cr_item_sk
), BestSellingItems AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    WHERE EXISTS (
        SELECT 1
        FROM RankedSales rs
        WHERE rs.ws_item_sk = ws.ws_item_sk AND rs.profit_rank = 1
    )
    GROUP BY ws.ws_item_sk
)
SELECT
    bsi.ws_item_sk,
    COALESCE(bsi.total_sold, 0) AS total_sold,
    COALESCE(fr.total_returns, 0) AS total_returns,
    (COALESCE(bsi.total_profit, 0) - COALESCE(fr.total_return_amount, 0)) AS net_profit_loss,
    CASE
        WHEN COALESCE(fr.total_return_amount, 0) > COALESCE(bsi.total_profit, 0) THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM BestSellingItems bsi
LEFT JOIN FilteredReturns fr ON bsi.ws_item_sk = fr.cr_item_sk
ORDER BY net_profit_loss DESC, ws_item_sk;