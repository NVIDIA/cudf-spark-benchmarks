
WITH customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),

top_customers AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_purchase_estimate
    FROM
        customer_details cd
    WHERE
        cd.rank <= 3
),

sales_data AS (
    SELECT
        ws.ws_ship_date_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        top_customers tc ON ws.ws_ship_customer_sk = tc.c_customer_sk
    GROUP BY
        ws.ws_ship_date_sk
),

average_sales AS (
    SELECT
        sd.ws_ship_date_sk,
        sd.total_sales,
        sd.total_orders,
        (sd.total_sales / NULLIF(sd.total_orders, 0)) AS avg_sales_per_order
    FROM
        sales_data sd
),

inventory_status AS (
    SELECT
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        MAX(inv.inv_date_sk) AS last_updated
    FROM
        inventory inv
    GROUP BY
        inv.inv_date_sk
),

final_report AS (
    SELECT
        ds.d_date_id,
        COALESCE(a.avg_sales_per_order, 0) AS average_sales_per_order,
        COALESCE(i.total_quantity_on_hand, 0) AS total_quantity_on_hand
    FROM
        date_dim ds
    LEFT JOIN
        average_sales a ON ds.d_date_sk = a.ws_ship_date_sk
    LEFT JOIN
        inventory_status i ON ds.d_date_sk = i.inv_date_sk
    WHERE
        ds.d_year = 2023
)

SELECT
    f.d_date_id,
    f.average_sales_per_order,
    f.total_quantity_on_hand,
    CASE
        WHEN f.average_sales_per_order > 1000 THEN 'High Sales'
        WHEN f.average_sales_per_order BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM
    final_report f
ORDER BY
    f.d_date_id;
