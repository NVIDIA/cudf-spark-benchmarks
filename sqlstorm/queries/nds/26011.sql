
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', 
               TRIM(ca_street_name), ' ', 
               TRIM(ca_street_type), ', ', 
               TRIM(ca_city), ', ', 
               TRIM(ca_state), ' ', 
               TRIM(ca_zip)) AS full_address,
        LENGTH(CONCAT(TRIM(ca_street_number), ' ', 
                      TRIM(ca_street_name), ' ', 
                      TRIM(ca_street_type), ', ', 
                      TRIM(ca_city), ', ', 
                      TRIM(ca_state), ' ', 
                      TRIM(ca_zip))) AS address_length
    FROM customer_address
    WHERE ca_country = 'USA'
),
demographic_analysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        COUNT(*) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
address_demographic_join AS (
    SELECT 
        pa.ca_address_sk,
        da.cd_demo_sk,
        da.total_purchase_estimate,
        pa.address_length
    FROM processed_addresses pa
    JOIN demographic_analysis da ON da.cd_demo_sk = pa.ca_address_sk
)
SELECT 
    AVG(address_length) AS avg_address_length,
    MAX(total_purchase_estimate) AS max_purchase_estimate,
    COUNT(DISTINCT ca_address_sk) AS unique_address_count
FROM address_demographic_join
WHERE total_purchase_estimate > 1000
GROUP BY cd_demo_sk
ORDER BY avg_address_length DESC;
