
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_suite_number, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_suite_number, ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS address_length
    FROM 
        customer_address
),
address_statistics AS (
    SELECT 
        AVG(address_length) AS avg_address_length,
        MIN(address_length) AS min_address_length,
        MAX(address_length) AS max_address_length,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses
    FROM 
        processed_addresses
),
demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
final_summary AS (
    SELECT 
        a.avg_address_length,
        a.min_address_length,
        a.max_address_length,
        d.cd_gender,
        d.customer_count,
        d.total_dependents
    FROM 
        address_statistics a
    CROSS JOIN 
        demographic_summary d
)
SELECT * 
FROM final_summary
ORDER BY avg_address_length DESC, customer_count DESC;
