
WITH  sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit
    FROM
        item i
    LEFT JOIN
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    WHERE
        i.i_current_price IS NOT NULL AND i.i_item_desc IS NOT NULL
),
recent_orders AS (
    SELECT DISTINCT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
)
SELECT
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    id.total_quantity,
    id.total_net_profit,
    ro.ws_order_number,
    dd.d_date AS order_date
FROM
    item_details id
LEFT JOIN
    recent_orders ro ON id.i_item_sk = ro.ws_item_sk
LEFT JOIN
    date_dim dd ON ro.ws_sold_date_sk = dd.d_date_sk
WHERE
    id.total_net_profit > 0
ORDER BY
    id.total_net_profit DESC,
    id.i_item_desc;
