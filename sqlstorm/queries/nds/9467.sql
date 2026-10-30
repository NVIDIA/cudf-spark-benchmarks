
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        ws_item_sk
),
top_sales AS (
    SELECT
        rs.ws_item_sk,
        rs.total_sales,
        rs.orders_count,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name
    FROM
        ranked_sales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    JOIN web_sales ws ON rs.ws_item_sk = ws.ws_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        rs.rank <= 5
)
SELECT
    ts.ws_item_sk,
    ts.total_sales,
    ts.orders_count,
    ts.i_item_desc,
    CONCAT(ts.c_first_name, ' ', ts.c_last_name) AS customer_name
FROM
    top_sales ts
ORDER BY
    ts.total_sales DESC;
