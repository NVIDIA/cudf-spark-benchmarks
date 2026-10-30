
WITH formatted_addresses AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END, 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_address,
        ca_address_sk,
        ca_city,
        ca_state
    FROM customer_address
), demographic_info AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer_demographics
), address_count AS (
    SELECT 
        ca_city,
        COUNT(*) AS total_addresses
    FROM formatted_addresses
    GROUP BY ca_city
)
SELECT 
    f.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_purchase_estimate,
    ad.total_addresses
FROM formatted_addresses f
JOIN demographic_info d ON f.ca_address_sk = d.cd_demo_sk
JOIN address_count ad ON f.ca_city = ad.ca_city
WHERE f.full_address LIKE '%Main St%'
ORDER BY ad.total_addresses DESC, d.cd_purchase_estimate DESC
LIMIT 20;
