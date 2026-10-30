
WITH  sales_data AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS row_num
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (
            SELECT
                d_date_sk
            FROM
                date_dim
            WHERE
                d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
        )
),
total_sales AS (
    SELECT
        ws_order_number,
        SUM(ws_sales_price * ws_quantity) AS total_order_value,
        COUNT(DISTINCT ws_item_sk) AS item_count
    FROM
        sales_data
    GROUP BY
        ws_order_number
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    ts.total_order_value,
    ts.item_count,
    CASE
        WHEN ts.total_order_value IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM
    total_sales ts
LEFT JOIN
    customer_data cd ON ts.ws_order_number = cd.c_customer_sk
WHERE
    cd.rank <= 5
ORDER BY
    ts.total_order_value DESC;
