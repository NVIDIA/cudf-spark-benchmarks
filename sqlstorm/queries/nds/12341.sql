
WITH sales_summary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT
        ws_item_sk,
        total_quantity,
        total_net_paid,
        ROW_NUMBER() OVER (ORDER BY total_quantity DESC) AS rn
    FROM
        sales_summary
)
SELECT
    ti.ws_item_sk,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_net_paid
FROM
    top_items ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE
    ti.rn <= 10;
