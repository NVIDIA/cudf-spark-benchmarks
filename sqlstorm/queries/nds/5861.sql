
WITH sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM
        customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    si.total_sales,
    si.order_count
FROM
    customer_info AS ci
JOIN
    sales_data AS si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE
    si.total_sales > 1000
ORDER BY
    si.total_sales DESC
LIMIT 10;
