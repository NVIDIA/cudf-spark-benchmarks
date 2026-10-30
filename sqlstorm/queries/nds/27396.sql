
WITH formatted_addresses AS (
    SELECT 
        CONCAT_WS(' ', 
            ca_street_number, 
            ca_street_name, 
            ca_street_type,
            COALESCE(ca_suite_number, '')
        ) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_address_sk
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COALESCE(cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
combined_data AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        fa.full_address,
        fa.ca_city,
        fa.ca_state,
        fa.ca_zip,
        COALESCE(sd.total_spent, 0) AS total_spent
    FROM 
        customer_info ci
    JOIN 
        formatted_addresses fa ON ci.c_customer_sk = fa.ca_address_sk
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
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
    total_spent,
    LENGTH(full_address) AS address_length,
    UPPER(full_name) AS upper_full_name
FROM 
    combined_data
WHERE 
    total_spent > (SELECT AVG(total_spent) FROM sales_data)
ORDER BY 
    total_spent DESC
LIMIT 100;
