
WITH CustomerFullName AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StreetAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
FullAddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(sa.full_address, ', ', sa.ca_city, ', ', sa.ca_state, ' ', sa.ca_zip, ', ', sa.ca_country) AS complete_address
    FROM 
        StreetAddress sa
    JOIN 
        customer_address ca ON sa.ca_address_sk = ca.ca_address_sk
),
GenderMaritalStats AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        COUNT(*) AS num_customers
    FROM 
        CustomerFullName
    GROUP BY 
        full_name, cd_gender, cd_marital_status
)
SELECT 
    gm.full_name,
    gm.cd_gender,
    gm.cd_marital_status,
    fai.complete_address,
    gm.num_customers
FROM 
    GenderMaritalStats gm
JOIN 
    FullAddressInfo fai ON gm.full_name LIKE '%' || SUBSTRING(fai.complete_address FROM 1 FOR 20) || '%'
WHERE 
    gm.num_customers > 1
ORDER BY 
    gm.cd_gender, gm.cd_marital_status, gm.num_customers DESC;
