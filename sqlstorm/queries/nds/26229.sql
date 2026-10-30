
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state AS state,
        ca_zip AS zip,
        ca_country,
        CHAR_LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_country) AS country_lower
    FROM 
        customer_address
),
FilteredDemographics AS (
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
    WHERE 
        cd_purchase_estimate >= 50000  
),
MergedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        pa.full_address,
        pa.city_upper,
        pa.state,
        pa.zip,
        pd.cd_gender,
        pd.cd_marital_status,
        pd.cd_education_status
    FROM 
        customer c
    JOIN 
        ProcessedAddresses pa ON c.c_current_addr_sk = pa.ca_address_sk
    JOIN 
        FilteredDemographics pd ON c.c_current_cdemo_sk = pd.cd_demo_sk
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    full_address,
    city_upper,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM 
    MergedData
ORDER BY 
    city_upper, full_name;
