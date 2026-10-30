
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper,
        LEFT(ca_zip, 5) AS zip_5
    FROM 
        customer_address
),
CountedDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
FinalOutput AS (
    SELECT 
        pa.full_address,
        pa.city_lower,
        pa.state_upper,
        pa.zip_5,
        cd.demographic_count,
        ROW_NUMBER() OVER (PARTITION BY pa.state_upper ORDER BY cd.demographic_count DESC) AS rank
    FROM 
        ProcessedAddresses pa
    JOIN 
        CountedDemographics cd ON pa.city_lower LIKE '%' || cd.cd_gender || '%'
)
SELECT 
    full_address,
    city_lower,
    state_upper,
    zip_5,
    demographic_count,
    rank
FROM 
    FinalOutput
WHERE 
    rank <= 5
ORDER BY 
    state_upper, demographic_count DESC;
