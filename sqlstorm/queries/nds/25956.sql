
WITH address_stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographic_stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_dep_count) AS avg_dep_count,
        MAX(cd_dep_count) AS max_dep_count,
        MIN(cd_dep_count) AS min_dep_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
combined_stats AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.avg_street_name_length,
        d.cd_gender,
        d.demographic_count,
        d.avg_dep_count
    FROM 
        address_stats a
    JOIN 
        demographic_stats d ON a.address_count > 100 OR d.demographic_count > 50
)
SELECT 
    ca_state,
    cd_gender,
    address_count,
    avg_street_name_length,
    avg_dep_count
FROM 
    combined_stats
WHERE 
    address_count > 50 AND avg_dep_count < 3
ORDER BY 
    address_count DESC, avg_dep_count ASC;
