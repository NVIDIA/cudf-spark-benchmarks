
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(REGEXP_REPLACE(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '[^a-zA-Z0-9]', '')) AS alphanumeric_count,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_street_name) AS street_name_lower
    FROM 
        customer_address
), demographic_summary AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    pa.ca_address_sk,
    pa.full_address,
    pa.city_upper,
    pa.street_name_lower,
    ds.cd_gender,
    ds.customer_count,
    ds.avg_purchase_estimate,
    COALESCE(pa.alphanumeric_count, 0) AS alphanumeric_count
FROM 
    processed_addresses pa
JOIN 
    demographic_summary ds ON ds.customer_count > 5
WHERE 
    pa.ca_state = 'CA'
ORDER BY 
    alphanumeric_count DESC, 
    ds.customer_count DESC
LIMIT 100;
