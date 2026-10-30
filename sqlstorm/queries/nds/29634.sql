
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_country) AS upper_country
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY') 
),
address_metrics AS (
    SELECT 
        COUNT(*) AS total_addresses,
        AVG(street_name_length) AS avg_street_name_length,
        MAX(LENGTH(full_address)) AS max_address_length,
        MIN(LENGTH(full_address)) AS min_address_length
    FROM 
        processed_addresses
),
demographic_gender AS (
    SELECT 
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    am.total_addresses,
    am.avg_street_name_length,
    am.max_address_length,
    am.min_address_length,
    dg.cd_gender,
    dg.customer_count
FROM 
    address_metrics am
CROSS JOIN 
    demographic_gender dg
ORDER BY 
    dg.customer_count DESC;
