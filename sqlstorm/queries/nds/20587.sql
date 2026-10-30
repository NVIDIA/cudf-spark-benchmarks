
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS order_rank
    FROM
        web_sales
    WHERE
        ws_net_profit > 0
        AND ws_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_dow = 1
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow = 7
        )
),
TopSales AS (
    SELECT
        ws_item_sk,
        COUNT(*) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        RankedSales
    WHERE
        profit_rank <= 5
    GROUP BY
        ws_item_sk
),
HighProfitItems AS (
    SELECT
        ts.ws_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        ts.total_net_profit
    FROM
        TopSales ts
    JOIN
        item i ON ts.ws_item_sk = i.i_item_sk
    WHERE
        ts.total_net_profit > (
            SELECT AVG(total_net_profit)
            FROM TopSales
        )
)
SELECT
    hpi.ws_item_sk,
    hpi.i_item_desc,
    hpi.i_current_price,
    hpi.i_brand,
    COALESCE(SUM(srs.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(srs.sr_return_amt), 0) AS total_return_amount,
    CASE
        WHEN hpi.total_net_profit > 10000 THEN 'High Profit'
        WHEN hpi.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM
    HighProfitItems hpi
LEFT JOIN
    store_returns srs ON hpi.ws_item_sk = srs.sr_item_sk
GROUP BY
    hpi.ws_item_sk, hpi.i_item_desc, hpi.i_current_price, hpi.i_brand, hpi.total_net_profit
HAVING
    COUNT(srs.sr_ticket_number) IS NULL OR COUNT(srs.sr_ticket_number) < (
        SELECT
            COUNT(*)
        FROM
            store_returns
        WHERE
            sr_return_quantity > 0
    ) / 10
ORDER BY
    hpi.total_net_profit DESC, hpi.i_item_desc ASC;
