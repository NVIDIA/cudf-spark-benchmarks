
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 AND
        ws.ws_sold_date_sk >= (SELECT MAX(d2.d_date_sk) FROM date_dim d2 WHERE d2.d_year = 2022)
    GROUP BY
        ws.ws_item_sk
),
top_items AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM
        ranked_sales rs
    JOIN
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE
        rs.sales_rank <= 10
)
SELECT
    ta.i_item_id,
    ta.i_item_desc,
    ta.total_quantity,
    ta.total_sales,
    CASE
        WHEN ta.total_sales > 10000 THEN 'High'
        WHEN ta.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM
    top_items ta
ORDER BY
    ta.total_sales DESC;
