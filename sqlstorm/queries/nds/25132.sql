
WITH Customer_Address_Concat AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type || 
               CASE WHEN ca_suite_number IS NOT NULL THEN ' Suite ' || TRIM(ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
        CASE WHEN cd_marital_status = 'S' THEN 'Single' ELSE 'Married' END AS marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count || ' Dependents' AS dependents_info
    FROM 
        customer_demographics
), Combined AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.gender,
        cd.marital_status,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.dependents_info
    FROM 
        customer c
    JOIN 
        Customer_Demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        Customer_Address_Concat ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    c_first_name || ' ' || c_last_name AS full_name,
    gender,
    marital_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip || ' ' || ca_country AS location,
    cd_purchase_estimate,
    cd_credit_rating,
    dependents_info
FROM 
    Combined
WHERE 
    UPPER(ca_city) LIKE UPPER('%York%')
ORDER BY 
    ca_state, full_name
LIMIT 100;
