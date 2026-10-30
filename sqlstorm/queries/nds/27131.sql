
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
benchmarking AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ci.cd_gender,
        si.total_sales,
        si.order_count,
        CASE 
            WHEN si.total_sales IS NULL THEN 'No Sales'
            WHEN si.total_sales < 100 THEN 'Low Spender'
            WHEN si.total_sales BETWEEN 100 AND 500 THEN 'Medium Spender'
            ELSE 'High Spender'
        END AS spending_category
    FROM customer_info ci
    LEFT JOIN sales_data si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    c.c_email_address,
    c.cd_gender,
    b.total_sales,
    b.order_count,
    b.spending_category,
    c.ca_city,
    c.ca_state,
    c.ca_country
FROM benchmarking b
JOIN customer_info c ON b.c_customer_sk = c.c_customer_sk
ORDER BY b.total_sales DESC NULLS LAST, c.c_last_name, c.c_first_name
LIMIT 100;
