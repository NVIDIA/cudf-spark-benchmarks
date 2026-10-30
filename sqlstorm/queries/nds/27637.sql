
WITH address_analysis AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length,
        REPLACE(LOWER(ca_city), ' ', '') AS normalized_city
    FROM 
        customer_address
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ARRAY_AGG(DISTINCT cd.cd_education_status) AS education_levels,
        aa.ca_address_sk,
        aa.full_address,
        aa.address_length,
        aa.normalized_city
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_analysis aa ON c.c_current_addr_sk = aa.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, aa.ca_address_sk, aa.full_address, aa.address_length, aa.normalized_city
)
SELECT 
    normalized_city,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    AVG(address_length) AS average_address_length,
    ARRAY_AGG(DISTINCT education_levels) AS unique_education_levels,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM 
    customer_analysis
GROUP BY 
    normalized_city
ORDER BY 
    total_customers DESC
LIMIT 10;
