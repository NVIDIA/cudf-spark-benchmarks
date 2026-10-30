
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_benchmark AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        cs.total_orders,
        cs.total_sales,
        cs.avg_order_value
    FROM customer_info ci
    LEFT JOIN sales_summary cs ON ci.c_customer_sk = cs.ws_bill_customer_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    ca_state,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_revenue,
    AVG(avg_order_value) AS average_order_value,
    MAX(total_orders) AS max_orders
FROM customer_benchmark
GROUP BY cd_gender, cd_marital_status, ca_state
ORDER BY ca_state, cd_gender, cd_marital_status;
