
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address 
    GROUP BY 
        ca_state
), CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dep_count,
        STRING_AGG(CAST(cd_demo_sk AS STRING), ',') AS demo_sk_list
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), CombinedStats AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.max_street_name_length,
        a.min_street_name_length,
        a.avg_street_name_length,
        c.cd_gender,
        c.total_customers,
        c.avg_dep_count,
        c.demo_sk_list
    FROM 
        AddressStats a
    JOIN 
        CustomerStats c ON c.total_customers > 100  
)
SELECT 
    ca_state,
    cd_gender,
    COUNT(*) AS total_customers_addressed,
    MAX(max_street_name_length) AS max_street_name_length,
    MIN(min_street_name_length) AS min_street_name_length,
    AVG(avg_dep_count) AS avg_dep_count
FROM 
    CombinedStats
GROUP BY 
    ca_state, cd_gender
ORDER BY 
    total_customers_addressed DESC;
