
WITH CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUBSTRING(c.c_email_address FROM 1 FOR 10) AS email_preview
    FROM
        customer AS c
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MIN(ds.d_date) AS first_purchase_date,
        MAX(ds.d_date) AS last_purchase_date
    FROM
        web_sales AS ws
    JOIN CustomerInfo AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim AS ds ON ws.ws_sold_date_sk = ds.d_date_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_marital_status,
    ci.cd_gender,
    ci.cd_education_status,
    ss.total_sales,
    ss.order_count,
    ss.first_purchase_date,
    ss.last_purchase_date,
    CASE
        WHEN ss.total_sales > 1000 THEN 'High Value'
        WHEN ss.total_sales > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM
    CustomerInfo AS ci
JOIN SalesSummary AS ss ON ci.c_customer_sk = ss.c_customer_sk
ORDER BY
    ss.total_sales DESC,
    ci.full_name;
