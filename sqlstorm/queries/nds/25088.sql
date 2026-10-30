
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
CombinedStats AS (
    SELECT 
        A.ca_state,
        A.total_addresses,
        A.avg_street_name_length,
        A.max_street_name_length,
        A.min_street_name_length,
        D.cd_gender,
        D.total_demographics,
        D.avg_purchase_estimate
    FROM 
        AddressStats A
    JOIN 
        Demographics D ON A.total_addresses BETWEEN D.total_demographics - 10 AND D.total_demographics + 10
)
SELECT 
    ca_state,
    total_addresses,
    avg_street_name_length,
    max_street_name_length,
    min_street_name_length,
    cd_gender,
    total_demographics,
    avg_purchase_estimate
FROM 
    CombinedStats
WHERE 
    avg_street_name_length > 30
ORDER BY 
    avg_purchase_estimate DESC, total_addresses DESC;
