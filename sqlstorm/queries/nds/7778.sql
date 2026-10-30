
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        ws.ws_item_sk, d.d_year, d.d_month_seq
),
TopSellingItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_amount,
        RANK() OVER (PARTITION BY sd.sales_year ORDER BY sd.total_quantity_sold DESC) AS rank,
        sd.sales_year
    FROM
        SalesData sd
)
SELECT
    ti.i_item_id,
    ti.i_item_desc,
    tsi.total_quantity_sold,
    tsi.total_sales_amount,
    tsi.rank
FROM
    TopSellingItems tsi
JOIN
    item ti ON tsi.ws_item_sk = ti.i_item_sk
WHERE
    tsi.rank <= 10
ORDER BY
    tsi.sales_year, tsi.rank;
