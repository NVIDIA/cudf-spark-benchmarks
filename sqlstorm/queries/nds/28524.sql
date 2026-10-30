
WITH AddressInfo AS (
    SELECT
        LOWER(TRIM(ca_street_name)) AS normalized_street_name,
        ca_city,
        ca_state,
        ca_country
    FROM customer_address
    WHERE ca_country = 'USA'
), DemographicInfo AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer_demographics
), CustomerInfo AS (
    SELECT
        c_first_name,
        c_last_name,
        c_email_address,
        CASE 
            WHEN c_birth_month IS NOT NULL AND c_birth_day IS NOT NULL THEN 
                CONCAT(c_first_name, ' ', c_last_name, ' born on ', c_birth_month, '/', c_birth_day)
            ELSE 
                CONCAT(c_first_name, ' ', c_last_name)
        END AS customer_identity
    FROM customer
)
SELECT
    ai.normalized_street_name,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status,
    di.cd_purchase_estimate,
    ci.customer_identity,
    CONCAT('Contact: ', ci.c_email_address) AS contact_details
FROM AddressInfo ai
JOIN DemographicInfo di ON ai.ca_city = 'San Francisco' AND di.cd_purchase_estimate > 1000
JOIN CustomerInfo ci ON ci.c_email_address LIKE '%@gmail.com%'
ORDER BY ai.ca_city, di.cd_purchase_estimate DESC;
