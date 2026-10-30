
WITH CustomerData AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        c.c_email_address,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FormattedData AS (
    SELECT 
        LOWER(full_name) AS name_lower,
        UPPER(full_name) AS name_upper,
        LENGTH(full_name) AS name_length,
        REPLACE(full_address, ' ', '-') AS address_hyphenated,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographic_code,
        CASE 
            WHEN (c_birth_year >= 1970 AND c_birth_year < 1980) THEN 'Generation X'
            WHEN (c_birth_year >= 1980 AND c_birth_year < 1995) THEN 'Millennial'
            WHEN (c_birth_year >= 1995) THEN 'Generation Z'
            ELSE 'Other'
        END AS generation
    FROM 
        CustomerData
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(name_length) AS avg_name_length,
    COUNT(DISTINCT demographic_code) AS unique_demographics,
    COUNT(DISTINCT generation) AS generation_count
FROM 
    FormattedData
WHERE 
    name_length > 15
GROUP BY 
    generation
ORDER BY 
    total_customers DESC;
