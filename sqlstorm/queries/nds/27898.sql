
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LOWER(TRIM(ca_city)) AS city,
        LOWER(TRIM(ca_state)) AS state
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StringBenchmark AS (
    SELECT 
        A.ca_address_sk,
        C.c_customer_sk,
        C.full_name,
        C.cd_gender,
        C.cd_marital_status,
        C.cd_education_status,
        C.cd_purchase_estimate,
        C.cd_credit_rating,
        LENGTH(A.full_address) AS address_length,
        LENGTH(C.full_name) AS name_length,
        INSTR(A.full_address, 'Street') AS street_position,
        INSTR(LOWER(C.full_name), 'john') AS john_position
    FROM 
        AddressParts A
    JOIN 
        CustomerDetails C ON A.ca_address_sk = C.c_customer_sk
)
SELECT 
    COUNT(*) AS total_records,
    AVG(address_length) AS avg_address_length,
    AVG(name_length) AS avg_name_length,
    SUM(CASE WHEN street_position > 0 THEN 1 ELSE 0 END) AS street_count,
    SUM(CASE WHEN john_position > 0 THEN 1 ELSE 0 END) AS john_count
FROM 
    StringBenchmark;
