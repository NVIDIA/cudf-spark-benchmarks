
WITH customer_full AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               COALESCE(CONCAT(' ', ca.ca_suite_number), '')) AS full_address,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count,
        MAX(ws_sold_date_sk) AS last_purchase_date,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
highlighted_customers AS (
    SELECT
        cf.full_name,
        cf.full_address,
        cf.c_birth_country,
        cf.cd_gender,
        cf.cd_marital_status,
        cf.cd_education_status,
        ss.total_spent,
        ss.order_count,
        ss.last_purchase_date
    FROM
        customer_full cf
    JOIN
        sales_summary ss ON cf.c_customer_sk = ss.ws_bill_customer_sk
    WHERE
        ss.rank <= 10
)
SELECT
    *,
    CASE 
        WHEN cd_gender = 'M' THEN 'Male'
        WHEN cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description,
    CASE 
        WHEN total_spent >= 1000 THEN 'High Value'
        WHEN total_spent >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    highlighted_customers
ORDER BY
    total_spent DESC;
