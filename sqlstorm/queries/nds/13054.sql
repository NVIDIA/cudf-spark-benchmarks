
WITH sales_summary AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk
)
SELECT
    dd.d_date,
    ss.total_sales,
    ss.total_orders
FROM
    sales_summary ss
JOIN
    date_dim dd ON ss.ws_sold_date_sk = dd.d_date_sk
WHERE
    dd.d_year = 2023
ORDER BY
    dd.d_date;
