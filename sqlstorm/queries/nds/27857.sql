
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(UPPER(ca_city)) AS city,
        ca_state,
        REPLACE(ca_zip, '-', '') AS zip_code,
        LENGTH(ca_country) AS country_length
    FROM customer_address
),
address_benchmark AS (
    SELECT 
        city,
        ca_state,
        COUNT(*) AS address_count,
        AVG(country_length) AS avg_country_length
    FROM processed_addresses
    WHERE city LIKE 'A%' 
    GROUP BY city, ca_state
),
customer_benchmark AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
),
final_benchmark AS (
    SELECT 
        ab.city,
        ab.ca_state,
        ab.address_count,
        cb.cd_gender,
        cb.cd_marital_status,
        cb.customer_count,
        cb.total_purchase_estimate
    FROM address_benchmark ab
    JOIN customer_benchmark cb ON ab.ca_state = cb.cd_marital_status
)
SELECT 
    city,
    ca_state,
    SUM(address_count) AS total_addresses,
    SUM(customer_count) AS total_customers,
    SUM(total_purchase_estimate) AS total_estimated_purchases
FROM final_benchmark
GROUP BY city, ca_state
ORDER BY city, ca_state;
