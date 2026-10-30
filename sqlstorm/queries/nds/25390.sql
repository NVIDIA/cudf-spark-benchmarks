
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        CHAR_LENGTH(ca_street_name) AS street_name_length
    FROM customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM customer_demographics
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CHAR_LENGTH(c.c_email_address) AS email_length,
        a.street_name_length
    FROM customer c 
    JOIN AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
BenchmarkResults AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        email_length,
        street_name_length,
        CASE 
            WHEN email_length BETWEEN 15 AND 25 THEN 'Short Email'
            WHEN email_length BETWEEN 26 AND 50 THEN 'Medium Email'
            ELSE 'Long Email'
        END AS email_category
    FROM CustomerAddresses
)
SELECT 
    ca_city, 
    ca_state, 
    email_category, 
    COUNT(*) AS customer_count, 
    AVG(street_name_length) AS avg_street_name_length
FROM BenchmarkResults
GROUP BY ca_city, ca_state, email_category
ORDER BY ca_city, ca_state, customer_count DESC;
