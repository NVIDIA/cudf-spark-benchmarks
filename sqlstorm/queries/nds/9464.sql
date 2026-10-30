
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_category
),
ranked_sales AS (
    SELECT
        d_year,
        d_month_seq,
        i_item_id,
        i_category,
        total_quantity,
        total_sales,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_summary
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.i_item_id,
    r.i_category,
    r.total_quantity,
    r.total_sales
FROM
    ranked_sales r
WHERE
    r.sales_rank <= 10
ORDER BY
    r.d_year,
    r.d_month_seq,
    r.total_sales DESC;
