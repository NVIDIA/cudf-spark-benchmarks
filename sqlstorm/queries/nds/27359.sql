
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_suite_number, ca_city, ca_state)) AS full_address,
        LOWER(ca_country) AS normalized_country
    FROM 
        customer_address
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), demographics_ranked AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.cd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ci.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer_info ci
), address_demographics AS (
    SELECT 
        d.full_address,
        d.normalized_country,
        dr.c_customer_sk,
        dr.full_name,
        dr.cd_gender,
        dr.cd_marital_status,
        dr.cd_education_status,
        dr.cd_purchase_estimate
    FROM 
        processed_addresses d
    JOIN 
        demographics_ranked dr ON dr.c_customer_sk = d.ca_address_sk
    WHERE 
        d.normalized_country IS NOT NULL
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    MAX(cd_purchase_estimate) AS max_purchase_estimate,
    MIN(cd_purchase_estimate) AS min_purchase_estimate
FROM 
    address_demographics
WHERE 
    cd_marital_status = 'M'
GROUP BY 
    normalized_country
ORDER BY 
    total_customers DESC;
