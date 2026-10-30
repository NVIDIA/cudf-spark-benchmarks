
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AggregatedData AS (
    SELECT 
        ca_state,
        COUNT(*) AS customer_count,
        AVG(email_length) AS avg_email_length,
        MAX(LENGTH(full_name)) AS max_name_length,
        MIN(LENGTH(full_name)) AS min_name_length
    FROM 
        CustomerData
    GROUP BY 
        ca_state
)
SELECT 
    ca_state,
    customer_count,
    avg_email_length,
    max_name_length,
    min_name_length,
    CASE 
        WHEN customer_count > 100 THEN 'High Activity'
        WHEN customer_count BETWEEN 50 AND 100 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    AggregatedData
ORDER BY 
    customer_count DESC;
