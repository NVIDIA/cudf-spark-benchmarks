
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        full_address,
        address_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses pa ON c.c_current_addr_sk = pa.ca_address_sk
),
selected_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.full_address,
        c.address_length,
        ROW_NUMBER() OVER (PARTITION BY c.cd_gender ORDER BY c.address_length DESC) AS address_rank
    FROM 
        customer_info c
)
SELECT 
    sc.c_customer_sk,
    sc.c_first_name,
    sc.c_last_name,
    sc.cd_gender,
    sc.cd_marital_status,
    sc.cd_education_status,
    sc.full_address,
    sc.address_length
FROM 
    selected_customers sc
WHERE 
    sc.address_rank <= 5
ORDER BY 
    sc.cd_gender, sc.address_length DESC;
