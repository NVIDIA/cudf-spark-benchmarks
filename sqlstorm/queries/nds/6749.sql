
WITH sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023 AND
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY
        ws.ws_item_sk
),
top_items AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        item i
    JOIN
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.order_count,
    CASE
        WHEN ti.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Item'
    END AS item_category
FROM
    top_items ti
WHERE
    ti.sales_rank <= 50
ORDER BY
    ti.sales_rank;
