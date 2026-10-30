
WITH cleaned_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
address_stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        COUNT(DISTINCT full_address) AS unique_addresses,
        MAX(LENGTH(full_address)) AS max_address_length,
        AVG(LENGTH(full_address)) AS avg_address_length
    FROM 
        cleaned_addresses
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state,
    a.address_count,
    a.unique_addresses,
    a.max_address_length,
    a.avg_address_length,
    cd.cd_gender,
    COUNT(c.c_customer_sk) AS customer_count,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    SUM(CASE WHEN cd.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_customers
FROM 
    address_stats a
JOIN 
    customer_address ca ON a.ca_state = ca.ca_state
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    a.ca_state, a.address_count, a.unique_addresses, a.max_address_length, a.avg_address_length, cd.cd_gender
ORDER BY 
    a.address_count DESC;
