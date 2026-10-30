
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(*) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_sales_price) / COUNT(*) AS avg_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
merged_data AS (
    SELECT
        ci.customer_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.cd_dep_count,
        ci.cd_dep_employed_count,
        ci.cd_dep_college_count,
        ci.ca_city,
        ci.ca_state,
        ss.total_orders,
        ss.total_sales,
        ss.avg_order_value
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT
    *,
    CASE
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM merged_data
WHERE cd_gender = 'F'
AND total_orders > 0
ORDER BY total_sales DESC
LIMIT 100;
