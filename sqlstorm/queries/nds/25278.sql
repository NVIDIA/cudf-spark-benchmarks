
WITH address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
customer_info AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spending,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
final_report AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        si.total_spending,
        si.total_orders
    FROM customer_info ci
    LEFT JOIN address_info ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    WHERE ci.cd_purchase_estimate >= 100
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    COALESCE(total_spending, 0) AS total_spending,
    COALESCE(total_orders, 0) AS total_orders
FROM final_report
ORDER BY total_spending DESC, full_name;
