WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY', 'TX')  
),
AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        AVG(street_name_length) AS avg_street_name_length,
        AVG(city_length) AS avg_city_length
    FROM ProcessedAddresses
    GROUP BY ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        COUNT(*) AS total_customers
    FROM customer_demographics
    WHERE cd_gender = 'F'  
    GROUP BY cd_demo_sk, cd_gender
)
SELECT 
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    a.avg_city_length,
    c.total_purchase_estimate,
    c.total_customers
FROM AddressStats a
JOIN CustomerDemographics c ON a.ca_state = 
    (CASE 
        WHEN c.total_purchase_estimate > 1000 THEN 'CA'
        ELSE 'TX'
    END)
ORDER BY a.ca_state;