
WITH ProcessedData AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name, 
        CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        cd.cd_gender, 
        cd.cd_marital_status,
        REPLACE(REPLACE(cd.cd_education_status, ' ', ''), ',', '') AS stripped_education_status
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedData AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        ca_country,
        COUNT(*) AS customer_count,
        COUNT(DISTINCT stripped_education_status) AS unique_education_levels
    FROM 
        ProcessedData
    GROUP BY 
        full_name, ca_city, ca_state, ca_country
)
SELECT 
    a.full_name, 
    a.ca_city, 
    a.ca_state, 
    a.ca_country, 
    a.customer_count,
    a.unique_education_levels,
    CASE 
        WHEN a.customer_count > 10 THEN 'High'
        WHEN a.customer_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS customer_density
FROM 
    AggregatedData AS a
ORDER BY 
    a.customer_count DESC, 
    a.full_name ASC
LIMIT 100;
