
WITH sales_data AS (
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_net_profit,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 5 ORDER BY d_date_sk LIMIT 1
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 5 ORDER BY d_date_sk DESC LIMIT 1
        )
    GROUP BY
        cs_item_sk
),
top_items AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_net_profit,
        sd.order_count,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        sales_data sd
    JOIN
        item i ON sd.cs_item_sk = i.i_item_sk
)
SELECT
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.avg_net_profit,
    ti.order_count
FROM
    top_items ti
WHERE
    ti.sales_rank <= 10
ORDER BY
    ti.total_sales DESC;
