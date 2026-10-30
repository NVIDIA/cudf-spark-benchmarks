
WITH AddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(*) AS total_addresses,
        SUBSTRING(ca_street_name, 1, 10) AS street_prefix
    FROM 
        customer_address 
    GROUP BY 
        ca_city, ca_state, SUBSTRING(ca_street_name, 1, 10)
),
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.unique_addresses,
    a.total_addresses,
    c.cd_gender,
    c.cd_marital_status,
    c.avg_purchase_estimate,
    c.total_dependencies,
    CONCAT(a.street_prefix, '...') AS street_sample
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.total_addresses > 100 AND c.total_dependencies > 5
WHERE 
    a.unique_addresses > 10
ORDER BY 
    a.ca_state, a.unique_addresses DESC, c.avg_purchase_estimate DESC
LIMIT 50;
