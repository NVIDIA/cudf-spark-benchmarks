
WITH sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        d.d_year,
        d.d_month_seq
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        ws.ws_item_sk, d.d_year, d.d_month_seq
),
top_items AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales,
        sd.avg_sales_price,
        sd.order_count,
        RANK() OVER (PARTITION BY sd.d_year ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        sales_data sd
)
SELECT
    i.i_item_id,
    i.i_product_name,
    ti.total_quantity_sold,
    ti.total_sales,
    ti.avg_sales_price,
    ti.order_count,
    ti.sales_rank
FROM
    top_items ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE
    ti.sales_rank <= 10
ORDER BY
    ti.sales_rank, i.i_product_name;
