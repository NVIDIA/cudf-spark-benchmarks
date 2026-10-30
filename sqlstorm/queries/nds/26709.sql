
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
combined_info AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        COALESCE(si.total_quantity, 0) AS total_quantity,
        COALESCE(si.total_sales, 0) AS total_sales
    FROM customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.ca_city,
    c.ca_state,
    c.total_quantity,
    c.total_sales,
    CASE 
        WHEN c.total_sales > 5000 THEN 'High Value'
        WHEN c.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM combined_info c
WHERE c.ca_state = 'CA'
ORDER BY c.total_sales DESC
LIMIT 100;
