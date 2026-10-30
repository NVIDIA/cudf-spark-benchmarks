
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LOWER(ca_city) AS city_lower,
        ca_state AS state_code,
        ca_zip AS zip_code,
        LENGTH(ca_country) AS country_length
    FROM 
        customer_address
),
demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
address_gender_summary AS (
    SELECT 
        pa.city_lower,
        pa.state_code,
        d.cd_gender,
        COUNT(*) AS address_count
    FROM 
        processed_addresses pa
    JOIN 
        customer c ON c.c_current_addr_sk = pa.ca_address_sk
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY 
        pa.city_lower, pa.state_code, d.cd_gender
)
SELECT 
    a.city_lower,
    a.state_code,
    a.cd_gender,
    a.address_count,
    d.avg_purchase_estimate,
    d.avg_dependents
FROM 
    address_gender_summary a
JOIN 
    demographic_summary d ON a.cd_gender = d.cd_gender
ORDER BY 
    a.city_lower, a.state_code, a.cd_gender;
