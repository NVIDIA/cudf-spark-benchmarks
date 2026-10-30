
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        store s ON ws.ws_ship_mode_sk = s.s_store_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31') 
        AND i.i_current_price > 50.00
    GROUP BY
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM
        RankedSales rs
    WHERE
        rs.sales_rank <= 5
)
SELECT
    ti.i_item_id,
    ti.i_item_desc,
    ti.i_current_price,
    tsi.total_quantity,
    tsi.total_sales
FROM
    TopSellingItems tsi
JOIN
    item ti ON tsi.ws_item_sk = ti.i_item_sk
ORDER BY
    tsi.total_sales DESC;
