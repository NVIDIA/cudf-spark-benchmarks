
WITH AddressDetails AS (
    SELECT 
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_address_sk
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_state IS NOT NULL
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_demo_sk
    FROM 
        customer_demographics
),
Combined AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        AddressDetails ad
    JOIN 
        customer c ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
Aggregated AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        Combined
    GROUP BY 
        ca_city, 
        ca_state
)
SELECT 
    ca_city,
    ca_state,
    total_addresses,
    total_purchase_estimate,
    avg_purchase_estimate,
    ROUND(LENGTH(ca_city) * LENGTH(ca_state) / total_addresses, 2) AS city_state_length_ratio
FROM 
    Aggregated
WHERE 
    total_addresses > 10 AND 
    avg_purchase_estimate > 150
ORDER BY 
    total_purchase_estimate DESC;
