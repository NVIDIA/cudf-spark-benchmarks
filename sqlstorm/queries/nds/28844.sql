
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(LENGTH(ca_street_name) + LENGTH(ca_city) + LENGTH(ca_zip)) AS total_string_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        SUBSTRING(cd_gender, 1, 1) AS gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
CombinedStats AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.total_string_length,
        c.gender,
        c.avg_purchase_estimate,
        c.total_dependents
    FROM 
        AddressStats a
    JOIN 
        CustomerStats c ON a.ca_state = c.gender
)
SELECT 
    ca_state,
    unique_addresses,
    total_string_length,
    gender,
    avg_purchase_estimate,
    total_dependents,
    CONCAT('State: ', ca_state, ', Addresses: ', unique_addresses) AS address_summary,
    CONCAT('Avg Purchase: $', ROUND(avg_purchase_estimate, 2), ', Total Dependents: ', total_dependents) AS customer_summary
FROM 
    CombinedStats 
WHERE 
    unique_addresses > 100
ORDER BY 
    total_string_length DESC, avg_purchase_estimate DESC;
