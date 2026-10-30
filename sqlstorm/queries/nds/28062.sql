
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
FinalCustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
StringBenchmark AS (
    SELECT 
        full_name, 
        full_address,
        LENGTH(full_name) AS name_length,
        LENGTH(full_address) AS address_length,
        REGEXP_REPLACE(full_address, '[^a-zA-Z0-9 ]', '') AS clean_address,
        LOWER(full_name) AS lower_name,
        UPPER(full_name) AS upper_name
    FROM 
        FinalCustomerDetails
)
SELECT 
    COUNT(*) AS total_records,
    AVG(name_length) AS average_name_length,
    AVG(address_length) AS average_address_length,
    SUM(LENGTH(clean_address)) AS total_clean_address_length,
    SUM(CASE WHEN d.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN d.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
FROM 
    StringBenchmark b
JOIN 
    FinalCustomerDetails d ON b.full_name = d.full_name;
