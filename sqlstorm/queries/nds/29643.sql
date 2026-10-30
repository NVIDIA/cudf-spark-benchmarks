
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StringBenchmarks AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        LENGTH(full_name) AS name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        LENGTH(cd_gender) AS gender_length,
        LENGTH(cd_marital_status) AS marital_status_length,
        LENGTH(cd_education_status) AS education_length,
        LENGTH(cd_credit_rating) AS credit_length
    FROM 
        CustomerInfo c
),
AggregatedResults AS (
    SELECT 
        AVG(name_length) AS avg_name_length,
        AVG(city_length) AS avg_city_length,
        AVG(state_length) AS avg_state_length,
        AVG(gender_length) AS avg_gender_length,
        AVG(marital_status_length) AS avg_marital_length,
        AVG(education_length) AS avg_education_length,
        AVG(credit_length) AS avg_credit_length
    FROM 
        StringBenchmarks
)
SELECT 
    * 
FROM 
    AggregatedResults;
