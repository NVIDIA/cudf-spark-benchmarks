
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_street_type LIKE '%Street%' THEN 1 ELSE 0 END) AS street_type_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
), CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics
    INNER JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
), CombinedStats AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.max_street_name_length,
        a.avg_street_name_length,
        a.street_type_count,
        c.cd_gender,
        c.total_customers,
        c.avg_dependents,
        c.max_purchase_estimate
    FROM 
        AddressStats a
    FULL OUTER JOIN 
        CustomerStats c ON a.ca_state IS NOT NULL AND c.cd_gender IS NOT NULL
) 
SELECT 
    ca_state,
    cd_gender,
    unique_addresses,
    max_street_name_length,
    avg_street_name_length,
    street_type_count,
    total_customers,
    avg_dependents,
    max_purchase_estimate
FROM 
    CombinedStats
ORDER BY 
    unique_addresses DESC, total_customers DESC;
