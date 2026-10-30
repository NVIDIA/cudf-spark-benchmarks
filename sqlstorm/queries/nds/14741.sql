
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws_item_sk
)

SELECT
    i.i_item_id,
    i.i_item_desc,
    s.total_quantity,
    s.total_sales,
    s.order_count
FROM
    sales_summary s
JOIN
    item i ON s.ws_item_sk = i.i_item_sk
ORDER BY
    s.total_sales DESC
LIMIT 100;
