
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'TX', 'NY')
),
AggregatedData AS (
    SELECT 
        cd.ca_city,
        cd.ca_state,
        COUNT(*) AS customer_count,
        AVG(cd.first_name_length) AS avg_first_name_length,
        AVG(cd.last_name_length) AS avg_last_name_length
    FROM 
        CustomerData cd
    GROUP BY 
        cd.ca_city, cd.ca_state
)
SELECT 
    ca_city AS city,
    ca_state AS state,
    customer_count,
    avg_first_name_length,
    avg_last_name_length,
    CONCAT('City: ', ca_city, ', State: ', ca_state, ', Count: ', customer_count) AS city_info 
FROM 
    AggregatedData
ORDER BY 
    customer_count DESC
LIMIT 10;
