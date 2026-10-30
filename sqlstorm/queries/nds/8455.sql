
WITH SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk
),
TopSellingItems AS (
    SELECT
        ws_item_sk,
        total_quantity,
        total_net_profit,
        RANK() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM
        SalesData
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    tsi.total_quantity,
    tsi.total_net_profit
FROM
    TopSellingItems tsi
JOIN
    item i ON tsi.ws_item_sk = i.i_item_sk
WHERE
    tsi.rank <= 10
ORDER BY
    tsi.total_net_profit DESC;
