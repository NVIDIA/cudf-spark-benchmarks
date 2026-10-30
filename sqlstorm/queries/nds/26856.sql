
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), Demographics AS (
    SELECT 
        cd_demo_sk,
        CASE
            WHEN LOWER(cd_gender) = 'm' THEN 'Male'
            WHEN LOWER(cd_gender) = 'f' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
), FullCustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        d.gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    full_name,
    full_address,
    gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    LTRIM(RTRIM(REGEXP_REPLACE(full_address, '[^0-9A-Za-z ]', ''))) AS cleaned_address
FROM 
    FullCustomerDetails
WHERE 
    LOWER(cd_marital_status) = 's'
ORDER BY 
    cd_purchase_estimate DESC
LIMIT 10;
