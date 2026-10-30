
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_number) AS street_number_length,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_street_type) AS street_type_length
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        TRIM(c_birth_country) AS cleaned_country
    FROM 
        customer
    INNER JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
CombinedDetails AS (
    SELECT 
        addr.ca_city,
        addr.ca_state,
        addr.full_address,
        cust.full_name,
        cust.cleaned_country,
        addr.street_number_length,
        addr.street_name_length,
        addr.street_type_length,
        LENGTH(cust.full_name) AS full_name_length,
        LENGTH(cust.cleaned_country) AS country_length
    FROM 
        AddressDetails addr
    JOIN 
        CustomerDetails cust ON addr.ca_city LIKE '%city%' OR addr.ca_state = 'NY'
)
SELECT 
    ca_state,
    COUNT(*) AS total_records,
    AVG(street_number_length) AS avg_street_number_length,
    AVG(street_name_length) AS avg_street_name_length,
    AVG(street_type_length) AS avg_street_type_length,
    AVG(full_name_length) AS avg_full_name_length,
    AVG(country_length) AS avg_country_length
FROM 
    CombinedDetails
GROUP BY 
    ca_state
ORDER BY 
    total_records DESC;
