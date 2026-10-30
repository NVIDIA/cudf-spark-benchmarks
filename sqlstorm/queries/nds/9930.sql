
WITH sales_summary AS (
    SELECT
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        d.d_year, d.d_month_seq
),
customer_summary AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
),
top_items AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_id
    ORDER BY
        total_quantity_sold DESC
    LIMIT 10
)
SELECT
    ss.sales_year,
    ss.sales_month,
    ss.total_sales,
    ss.avg_sales_price,
    ss.total_orders,
    ss.total_quantity,
    cs.total_customers,
    cs.avg_purchase_estimate,
    ti.i_item_id,
    ti.total_quantity_sold
FROM
    sales_summary ss
JOIN
    customer_summary cs ON ss.sales_year = 2023
CROSS JOIN
    top_items ti
ORDER BY
    ss.sales_year, ss.sales_month;
