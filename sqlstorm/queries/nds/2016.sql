
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales ws
    LEFT JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        ws.ws_item_sk
),
recent_returns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM
        catalog_returns cr
    WHERE
        cr.cr_returned_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_date >= DATE '2002-10-01' - INTERVAL '30 days'
        )
    GROUP BY
        cr.cr_item_sk
),
sales_summary AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COALESCE(rs.total_quantity, 0) AS total_quantity_sold,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rr.total_return_amount, 0) AS total_return_amount
    FROM
        item i
    LEFT JOIN
        ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN
        recent_returns rr ON i.i_item_sk = rr.cr_item_sk
)
SELECT
    i_item_id AS ITEM_ID,
    i_item_desc AS ITEM_DESC,
    total_quantity_sold,
    total_sales,
    total_return_quantity,
    total_return_amount,
    (total_sales - total_return_amount) AS net_sales,
    CASE
        WHEN total_sales >= 1000 THEN 'High Sales'
        WHEN total_sales < 100 THEN 'Low Sales'
        ELSE 'Medium Sales'
    END AS sales_category
FROM
    sales_summary
WHERE
    total_quantity_sold > 0
ORDER BY
    total_sales DESC
LIMIT 10;
