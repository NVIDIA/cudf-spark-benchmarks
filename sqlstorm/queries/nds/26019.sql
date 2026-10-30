
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        TRIM(BOTH ' ' FROM COALESCE(NULLIF(ca_street_number, ''), 'N/A')) AS street_number,
        TRIM(BOTH ' ' FROM COALESCE(NULLIF(ca_street_name, ''), 'Unknown Street')) AS street_name,
        TRIM(BOTH ' ' FROM COALESCE(NULLIF(ca_street_type, ''), 'N/A')) AS street_type,
        TRIM(BOTH ' ' FROM COALESCE(NULLIF(ca_city, ''), 'Unknown City')) AS city,
        TRIM(BOTH ' ' FROM COALESCE(NULLIF(ca_state, ''), 'Unknown State')) AS state,
        TRIM(BOTH ' ' FROM COALESCE(NULLIF(ca_zip, ''), '00000')) AS zip,
        TRIM(BOTH ' ' FROM COALESCE(NULLIF(ca_country, ''), 'Unknown Country')) AS country
    FROM customer_address
),
MergedAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(street_number, ' ', street_name, ' ', street_type, ', ', city, ', ', state, ' ', zip, ', ', country) AS full_address
    FROM AddressComponents
),
DemographicDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_dep_count,
        d.cd_dep_employed_count
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    m.full_address,
    d.customer_name,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    CASE
        WHEN d.cd_dep_count > 0 THEN 'Has Dependents'
        ELSE 'No Dependents'
    END AS dependent_status
FROM MergedAddress m
JOIN DemographicDetails d ON m.ca_address_sk = d.c_customer_sk
ORDER BY m.full_address, d.customer_name;
