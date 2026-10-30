
WITH string_benchmark AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        ca.ca_street_name || ', ' || ca.ca_city || ', ' || ca.ca_state || ' ' || ca.ca_zip AS full_address,
        cd.cd_marital_status,
        cd.cd_gender,
        REPLACE(c.c_email_address, '@', '[at]') AS masked_email,
        LENGTH(c.c_email_address) AS email_length,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS name_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status IN ('M', 'S')
),
address_stats AS (
    SELECT 
        full_address,
        COUNT(*) AS address_count,
        AVG(email_length) AS avg_email_length,
        AVG(name_length) AS avg_name_length
    FROM 
        string_benchmark
    GROUP BY 
        full_address
)
SELECT 
    full_address,
    address_count,
    ROUND(avg_email_length, 2) AS avg_email_length,
    ROUND(avg_name_length, 2) AS avg_name_length
FROM 
    address_stats
WHERE 
    address_count > 1
ORDER BY 
    address_count DESC
LIMIT 10;
