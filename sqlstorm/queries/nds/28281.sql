
WITH address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
full_info AS (
    SELECT 
        ci.customer_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_credit_rating,
        ci.cd_dep_count,
        ci.cd_dep_employed_count,
        ci.cd_dep_college_count,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.ca_country
    FROM 
        customer_info ci
    JOIN 
        address_info ai ON ci.c_customer_sk = ai.ca_address_sk
)
SELECT 
    customer_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    CD_credit_rating,
    cd_dep_count,
    cd_dep_employed_count,
    cd_dep_college_count,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    LENGTH(full_address) AS address_length,
    UPPER(full_address) AS address_uppercase,
    REPLACE(full_address, ' ', '-') AS address_hyphenated
FROM 
    full_info
WHERE 
    cd_gender = 'F'
    AND cd_marital_status = 'M'
ORDER BY 
    address_length DESC
LIMIT 100;
