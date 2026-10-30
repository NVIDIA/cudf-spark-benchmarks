
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        COALESCE(NULLIF(TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', ca_suite_number)), ''), 'N/A') AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        COALESCE(cd.cd_education_status, 'N/A') AS education_status,
        CAST(COALESCE(cd.cd_purchase_estimate, 0) AS STRING) AS purchase_estimate,
        COALESCE(a.full_address, 'Unknown') AS address,
        a.ca_city AS city,
        a.ca_state AS state,
        a.ca_zip AS zip,
        a.ca_country AS country
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
BenchmarkResults AS (
    SELECT 
        full_name,
        gender,
        marital_status,
        education_status,
        purchase_estimate,
        CONCAT_WS(', ', city, state, zip, country) AS full_location
    FROM 
        CustomerDetails
)
SELECT 
    gender,
    marital_status,
    education_status,
    COUNT(*) AS customer_count,
    AVG(NULLIF(CAST(purchase_estimate AS integer), 0)) AS avg_purchase_estimate
FROM 
    BenchmarkResults
GROUP BY 
    gender, marital_status, education_status
ORDER BY 
    gender, customer_count DESC;
