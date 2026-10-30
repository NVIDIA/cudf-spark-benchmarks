
WITH sales_data AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        i.i_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year,
        d.d_month_seq
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY
        w.w_warehouse_id, i.i_item_id, d.d_year, d.d_month_seq
), ranked_sales AS (
    SELECT
        warehouse_id,
        item_id,
        total_quantity_sold,
        total_sales,
        total_orders,
        ROW_NUMBER() OVER (PARTITION BY warehouse_id ORDER BY total_sales DESC) AS rank
    FROM
        sales_data
)
SELECT
    warehouse_id,
    item_id,
    total_quantity_sold,
    total_sales,
    total_orders
FROM
    ranked_sales
WHERE
    rank <= 10
ORDER BY
    warehouse_id,
    total_sales DESC;
