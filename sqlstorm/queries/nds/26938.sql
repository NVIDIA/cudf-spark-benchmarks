
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country)) AS full_address,
        LENGTH(TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country))) AS address_length
    FROM 
        customer_address
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        pa.full_address,
        pa.address_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses pa ON c.c_current_addr_sk = pa.ca_address_sk
),
popular_states AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
    ORDER BY 
        address_count DESC
    LIMIT 5
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.cd_dep_count,
    cd.cd_dep_employed_count,
    cd.cd_dep_college_count,
    cd.full_address,
    cd.address_length,
    ps.address_count AS popular_state_count
FROM 
    customer_details cd
JOIN 
    popular_states ps ON ps.ca_state = SUBSTRING(cd.full_address FROM '([A-Z]{2})$')
ORDER BY 
    cd.cd_purchase_estimate DESC;
