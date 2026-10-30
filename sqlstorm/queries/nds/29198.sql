
WITH demographic_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM customer_address ca
),
sales_info AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM web_sales ws
    GROUP BY ws.ws_ship_customer_sk
),
combined_info AS (
    SELECT 
        di.full_name,
        di.cd_gender,
        di.cd_marital_status,
        di.cd_education_status,
        di.cd_purchase_estimate,
        di.cd_credit_rating,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        si.total_sales,
        si.order_count,
        si.avg_order_value
    FROM demographic_info di
    JOIN address_info ai ON di.c_customer_sk = ai.ca_address_sk
    JOIN sales_info si ON di.c_customer_sk = si.ws_ship_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    order_count,
    avg_order_value,
    CASE 
        WHEN total_sales > 5000 THEN 'High Value'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Mid Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM combined_info
ORDER BY total_sales DESC;
