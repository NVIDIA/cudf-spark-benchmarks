
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY c.c_birth_year ASC) AS birth_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND ca.ca_state IN ('CA', 'NY')
),
StringBenchmarks AS (
    SELECT 
        DISTINCT 
        full_name,
        LENGTH(full_name) AS name_length,
        UPPER(full_name) AS upper_name,
        LOWER(full_name) AS lower_name,
        LEFT(full_name, 10) AS short_name,
        RIGHT(full_name, 10) AS end_part_name
    FROM 
        CustomerInfo
    WHERE 
        birth_rank <= 10
),
AggregatedData AS (
    SELECT 
        AVG(name_length) AS avg_length,
        COUNT(*) AS total_names,
        COUNT(DISTINCT full_name) AS unique_names
    FROM 
        StringBenchmarks
)
SELECT 
    avg_length,
    total_names,
    unique_names,
    CASE 
        WHEN avg_length < 50 THEN 'Short'
        WHEN avg_length BETWEEN 50 AND 70 THEN 'Medium'
        ELSE 'Long'
    END AS name_length_category
FROM 
    AggregatedData;
