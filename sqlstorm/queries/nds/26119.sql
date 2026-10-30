
WITH Address_Components AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', TRIM(ca_suite_number)) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN Address_Components a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Aggregated_Data AS (
    SELECT 
        ci.ca_state,
        COUNT(DISTINCT ci.c_customer_sk) AS total_customers,
        COUNT(DISTINCT CASE WHEN ci.cd_gender = 'M' THEN ci.c_customer_sk END) AS male_customers,
        COUNT(DISTINCT CASE WHEN ci.cd_gender = 'F' THEN ci.c_customer_sk END) AS female_customers,
        ARRAY_AGG(DISTINCT ci.full_address) AS unique_addresses
    FROM Customer_Info ci
    GROUP BY ci.ca_state
)
SELECT 
    ad.ca_state,
    ad.total_customers,
    ad.male_customers,
    ad.female_customers,
    ad.unique_addresses,
    (SELECT COUNT(*) FROM item) AS total_items
FROM Aggregated_Data ad
ORDER BY ad.total_customers DESC;
