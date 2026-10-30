
WITH address_parts AS (
    SELECT 
        ca_address_sk, 
        TRIM(ca_street_number) AS street_number, 
        TRIM(ca_street_name) AS street_name, 
        TRIM(ca_street_type) AS street_type, 
        TRIM(ca_suite_number) AS suite_number, 
        TRIM(ca_city) AS city, 
        TRIM(ca_state) AS state, 
        TRIM(ca_zip) AS zip,
        TRIM(ca_country) AS country
    FROM 
        customer_address
),
formatted_address AS (
    SELECT
        ca_address_sk,
        CONCAT_WS(' ', street_number, street_name, street_type, suite_number, city, state, zip, country) AS full_address
    FROM 
        address_parts
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        fa.full_address 
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        formatted_address fa ON ca.ca_address_sk = fa.ca_address_sk
)
SELECT 
    customer_name,
    full_address,
    cd_gender,
    cd_marital_status,
    COUNT(*) AS purchase_count
FROM 
    customer_data
JOIN 
    web_sales ws ON customer_data.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sales_price > 0
GROUP BY 
    customer_name, full_address, cd_gender, cd_marital_status
ORDER BY 
    purchase_count DESC
LIMIT 50;
