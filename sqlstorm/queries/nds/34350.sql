
WITH  sales_data AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ship_date_sk,
        d.d_date AS order_date,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ship_date_sk) AS order_rank
    FROM
        web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS ranking
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),
sales_summary AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_sales_price) AS total_sales,
        COUNT(sd.ws_order_number) AS total_orders,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT sd.order_date) AS unique_sales_days
    FROM
        sales_data sd
    WHERE
        sd.order_rank <= 5
    GROUP BY
        sd.ws_item_sk
)
SELECT
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_marital_status,
    cs.cd_gender,
    ss.total_sales,
    ss.total_orders,
    ss.avg_sales_price,
    ss.unique_sales_days
FROM
    sales_summary ss
JOIN customer_info cs ON cs.ranking <= 10
LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = ss.ws_item_sk
WHERE
    (ss.total_sales > 1000 OR ss.avg_sales_price > 20.00)
    AND cs.cd_gender IS NOT NULL
ORDER BY
    ss.total_sales DESC, cs.c_last_name ASC
LIMIT 50;
