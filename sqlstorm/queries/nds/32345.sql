
WITH  sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_bill_customer_sk
),
top_customers AS (
    SELECT
        c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        sales_summary cs
    JOIN
        customer c ON cs.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cs.sales_rank <= 10
),
customer_addresses AS (
    SELECT
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM
        customer c
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
aggregated_data AS (
    SELECT
        tc.c_customer_id,
        tc.total_sales,
        tc.total_orders,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        COALESCE(NULLIF(tc.cd_gender, 'U'), 'Unknown') AS gender,
        COALESCE(NULLIF(tc.cd_marital_status, 'U'), 'Unknown') AS marital_status
    FROM
        top_customers tc
    JOIN
        customer_addresses ca ON tc.c_customer_id = ca.c_customer_id
)
SELECT
    ad.c_customer_id,
    ad.total_sales,
    ad.total_orders,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.gender,
    ad.marital_status,
    CASE 
        WHEN ad.total_sales > 1000 THEN 'High Value'
        WHEN ad.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM
    aggregated_data ad
ORDER BY
    ad.total_sales DESC;
