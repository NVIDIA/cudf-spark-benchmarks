
WITH sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws_bill_customer_sk
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sd.total_sales,
        sd.total_discounts,
        sd.total_orders
    FROM
        customer_data AS cd
    LEFT JOIN
        sales_data AS sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    s.c_first_name,
    s.c_last_name,
    s.cd_gender,
    s.cd_marital_status,
    s.cd_education_status,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_discounts, 0) AS total_discounts,
    s.total_orders
FROM
    sales_summary AS s
ORDER BY
    total_sales DESC
LIMIT 100;
