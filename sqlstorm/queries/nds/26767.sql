
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address,
        REGEXP_REPLACE(ca_city, '[^A-Za-z ]', '') AS clean_city,
        UPPER(ca_state) AS upper_state,
        LEFT(ca_zip, 5) AS zip_prefix
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_purchase_estimate,
        CONCAT(REPLACE(cd.cd_credit_rating, ' ', ''), ' - ', cd.cd_education_status) AS credit_info
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    pa.full_address,
    pa.clean_city,
    pa.upper_state,
    pa.zip_prefix,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_sales, 0.00) AS total_sales
FROM 
    customer_info ci
JOIN 
    processed_addresses pa ON ci.c_customer_sk = pa.ca_address_sk
LEFT JOIN 
    sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    pa.clean_city LIKE '%New%' AND
    ci.cd_marital_status = 'M'
ORDER BY 
    total_sales DESC
LIMIT 100;
