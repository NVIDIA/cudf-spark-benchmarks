
WITH CustomerAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, ''), ca_city, ca_state, ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status) AS demographics
    FROM 
        customer_demographics
),
CombinedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.full_address,
        cd.demographics
    FROM 
        customer c
    JOIN 
        CustomerAddress ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Benchmark AS (
    SELECT 
        LEFT(c.full_address, 50) AS short_address,
        LENGTH(c.full_address) AS address_length,
        c.demographics
    FROM 
        CombinedData c
)

SELECT 
    short_address, 
    AVG(address_length) AS average_length, 
    COUNT(demographics) AS demographic_count
FROM 
    Benchmark
GROUP BY 
    short_address
ORDER BY 
    average_length DESC;
