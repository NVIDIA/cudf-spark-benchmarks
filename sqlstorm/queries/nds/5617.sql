
WITH RankedSales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS revenue_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopItems AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        total_quantity,
        total_revenue
    FROM
        RankedSales
    WHERE
        revenue_rank <= 10
)
SELECT
    di.d_date AS sale_date,
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_revenue
FROM
    TopItems ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
JOIN
    date_dim di ON ti.ws_sold_date_sk = di.d_date_sk
ORDER BY
    di.d_date, ti.total_revenue DESC;
