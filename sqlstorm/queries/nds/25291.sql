
WITH AddressAggregation AS (
    SELECT 
        ca_state, 
        CONCAT(ca_city, ', ', ca_street_name, ' ', ca_street_number) AS full_address, 
        COUNT(*) AS address_count,
        SUM(LENGTH(ca_street_name) + LENGTH(ca_street_type) + LENGTH(ca_street_number)) AS total_char_count
    FROM 
        customer_address 
    GROUP BY 
        ca_state, ca_city, ca_street_name, ca_street_number
), CustomerStats AS (
    SELECT 
        cd_gender, 
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender
), DetailedReport AS (
    SELECT 
        a.ca_state,
        a.full_address,
        a.address_count,
        a.total_char_count,
        c.cd_gender,
        c.max_purchase_estimate,
        c.min_purchase_estimate,
        c.avg_purchase_estimate,
        c.total_dependents
    FROM 
        AddressAggregation a
    JOIN 
        CustomerStats c ON a.address_count > c.total_dependents
)
SELECT 
    ca_state,
    full_address,
    address_count,
    total_char_count,
    cd_gender,
    max_purchase_estimate,
    min_purchase_estimate,
    avg_purchase_estimate,
    total_dependents
FROM 
    DetailedReport
ORDER BY 
    ca_state, address_count DESC;
