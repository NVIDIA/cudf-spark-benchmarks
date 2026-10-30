
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            ELSE 'Female' 
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer_demographics
),
CustomerAddressDemographic AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS customer_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        d.gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM customer c
    JOIN AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN DemographicDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
PopularCities AS (
    SELECT 
        ca_city,
        COUNT(*) AS total_customers
    FROM CustomerAddressDemographic
    GROUP BY ca_city
    HAVING COUNT(*) > 100
)
SELECT 
    cad.customer_name,
    cad.full_address,
    cad.ca_city,
    cad.ca_state,
    cad.ca_zip,
    cad.ca_country,
    cad.gender,
    cad.cd_marital_status,
    cad.cd_education_status,
    cad.cd_purchase_estimate,
    pc.total_customers
FROM CustomerAddressDemographic cad
JOIN PopularCities pc ON cad.ca_city = pc.ca_city
ORDER BY pc.total_customers DESC, cad.customer_name;
