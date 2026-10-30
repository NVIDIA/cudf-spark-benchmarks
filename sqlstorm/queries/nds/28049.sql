
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || 
        UPPER(ca_street_name) || ' ' || 
        UPPER(ca_street_type) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip
    FROM customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        INITCAP(cd_education_status) AS education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CASE 
            WHEN cd_dep_count > 0 THEN 'With Dependents'
            ELSE 'No Dependents'
        END AS dependents_status
    FROM customer_demographics
),
FullCustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        c.c_birth_country,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.education_status,
        d.dependents_status
    FROM customer c
    JOIN AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN DemographicInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    customer_name,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    education_status,
    dependents_status,
    COUNT(*) OVER (PARTITION BY ca_state) AS num_customers_in_state
FROM FullCustomerInfo
WHERE cd_gender = 'F'
AND ca_state IN ('CA', 'NY')
ORDER BY ca_city, customer_name;
