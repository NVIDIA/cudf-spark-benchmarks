
WITH String_Processed AS (
    SELECT 
        ca_city,
        ca_state,
        ca_country,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_country) AS country_upper,
        REPLACE(ca_zip, '-', '') AS cleaned_zip
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND
        ca_state IS NOT NULL
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demo_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender IS NOT NULL
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
Final_Benchmark AS (
    SELECT 
        sp.ca_city,
        sp.full_address,
        sp.street_name_length,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.demo_count
    FROM 
        String_Processed sp
    JOIN 
        Demographics d ON sp.ca_state = d.cd_gender
    ORDER BY 
        sp.street_name_length DESC, d.demo_count ASC
)
SELECT 
    *
FROM 
    Final_Benchmark
LIMIT 100;
