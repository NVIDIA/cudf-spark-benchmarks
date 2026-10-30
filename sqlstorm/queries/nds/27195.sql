
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS formatted_address,
        LOWER(TRIM(ca_city)) AS lower_city,
        UPPER(TRIM(ca_state)) AS upper_state,
        TRIM(ca_zip) AS clean_zip
    FROM 
        customer_address
),
demographic_summary AS (
    SELECT 
        cd_demo_sk,
        COUNT(c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk
)
SELECT 
    a.ca_address_id,
    a.formatted_address,
    a.lower_city,
    a.upper_state,
    a.clean_zip,
    d.customer_count,
    d.total_dependents,
    d.avg_purchase_estimate
FROM 
    processed_addresses a
JOIN 
    demographic_summary d ON a.ca_address_sk = d.cd_demo_sk
WHERE 
    a.lower_city LIKE 'san%'
ORDER BY 
    d.customer_count DESC
LIMIT 10;
