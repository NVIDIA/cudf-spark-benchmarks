
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
SalesWithReturns AS (
    SELECT
        ws.ws_item_sk,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        web_sales ws
    LEFT JOIN
        CustomerReturns rs ON ws.ws_item_sk = rs.wr_item_sk
    GROUP BY
        ws.ws_item_sk, rs.total_returns, rs.total_return_amount
)
SELECT
    s.ws_item_sk,
    s.total_net_profit,
    s.total_returns,
    s.total_return_amount,
    CASE 
        WHEN s.total_returns = 0 THEN s.total_net_profit
        ELSE s.total_net_profit - s.total_return_amount 
    END AS net_profit_after_returns
FROM
    SalesWithReturns s
WHERE
    s.ws_item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE rn <= 5)
ORDER BY
    net_profit_after_returns DESC;
