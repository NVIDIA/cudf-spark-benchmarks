
WITH sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023 AND
        (cd.cd_gender = 'M' OR cd.cd_gender = 'F') AND
        (cd.cd_marital_status = 'M' OR cd.cd_marital_status = 'S')
    GROUP BY
        ws.ws_item_sk
),
top_items AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM
        sales_summary ss
)
SELECT
    ti.ws_item_sk,
    i.i_product_name,
    ti.total_quantity,
    ti.total_sales,
    ti.total_orders
FROM
    top_items ti
JOIN
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE
    ti.sales_rank <= 10
ORDER BY
    ti.total_sales DESC;
