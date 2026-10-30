
WITH sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        ws.ws_item_sk
),
top_items AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count
    FROM
        sales_summary ss
    WHERE
        ss.sales_rank <= 10
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Undisclosed'
            ELSE CAST(cd.cd_purchase_estimate AS STRING)
        END AS purchase_estimate_display
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
return_info AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM
        store_returns sr
    GROUP BY
        sr.sr_item_sk
)
SELECT
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    COALESCE(ri.total_returns, 0) AS total_returns,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.purchase_estimate_display
FROM
    top_items ti
LEFT JOIN
    return_info ri ON ti.ws_item_sk = ri.sr_item_sk
INNER JOIN
    customer_info ci ON ti.total_sales > 1000 AND ci.cd_marital_status = 'M'
ORDER BY
    ti.total_sales DESC, ci.c_last_name ASC;
