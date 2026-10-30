
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid_inc_ship_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_ship_tax) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws_item_sk
),
HighSales AS (
    SELECT
        rs.ws_item_sk,
        rs.total_sales,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM
        RankedSales rs
    JOIN
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE
        rs.sales_rank <= 10
)
SELECT
    h.ws_item_sk,
    h.total_sales,
    h.i_item_desc,
    h.i_current_price,
    h.i_brand,
    COALESCE((SELECT SUM(sr_return_quantity) FROM store_returns sr WHERE sr.sr_item_sk = h.ws_item_sk), 0) AS total_returns,
    (h.total_sales - COALESCE((SELECT SUM(sr_return_amt_inc_tax) FROM store_returns sr WHERE sr.sr_item_sk = h.ws_item_sk), 0)) AS net_sales
FROM
    HighSales h
ORDER BY
    h.total_sales DESC;
