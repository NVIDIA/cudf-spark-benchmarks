
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
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
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
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
        ci.ca_country,
        ss.total_sales,
        ss.total_orders,
        CASE 
            WHEN ss.total_sales > 1000 THEN 'High Value'
            WHEN ss.total_sales > 100 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    ca_city,
    ca_state,
    customer_value_segment,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS average_sales,
    AVG(total_orders) AS average_orders
FROM customer_benchmark
GROUP BY 
    ca_city, 
    ca_state, 
    customer_value_segment
ORDER BY 
    ca_state, 
    ca_city, 
    customer_value_segment;
