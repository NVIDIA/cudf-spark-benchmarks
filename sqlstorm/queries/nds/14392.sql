WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2459580 AND 2459610  
    GROUP BY
        ws_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ss.total_sales,
    ss.total_orders
FROM
    sales_summary ss
JOIN
    item i ON ss.ws_item_sk = i.i_item_sk
ORDER BY
    ss.total_sales DESC
LIMIT 100;