
WITH sales_summary AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        w.w_warehouse_name,
        d.d_year,
        i.i_category
),
top_sales AS (
    SELECT
        w_warehouse_name,
        d_year,
        i_category,
        total_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_summary
)
SELECT
    w_warehouse_name,
    d_year,
    i_category,
    total_sales
FROM
    top_sales
WHERE
    sales_rank <= 5
ORDER BY
    d_year,
    total_sales DESC;
