
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_label
    FROM 
        customer_demographics
),
JoinData AS (
    SELECT 
        ca.ca_address_sk,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        dm.cd_demo_sk,
        dm.gender_label,
        dm.cd_marital_status,
        dm.cd_education_status,
        dm.cd_purchase_estimate
    FROM 
        AddressComponents ca
    LEFT JOIN 
        Demographics dm ON ca.ca_address_sk = dm.cd_demo_sk
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    gender_label,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(cd_demo_sk) AS customer_count
FROM 
    JoinData
WHERE 
    ca_state = 'CA'
GROUP BY 
    full_address, ca_city, ca_state, ca_zip, gender_label
ORDER BY 
    customer_count DESC
LIMIT 50;
