
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
FullStats AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.max_street_name_length,
        a.min_street_name_length,
        a.avg_street_name_length,
        c.cd_gender,
        c.customer_count,
        c.max_purchase_estimate,
        c.min_purchase_estimate,
        c.avg_purchase_estimate
    FROM 
        AddressStats a
    JOIN 
        CustomerStats c ON a.ca_state IS NOT NULL
)
SELECT 
    fs.ca_state,
    fs.address_count,
    fs.max_street_name_length,
    fs.min_street_name_length,
    fs.avg_street_name_length,
    fs.cd_gender,
    fs.customer_count,
    fs.max_purchase_estimate,
    fs.min_purchase_estimate,
    fs.avg_purchase_estimate,
    CONCAT('State: ', fs.ca_state, ', Gender: ', fs.cd_gender) AS combined_info
FROM 
    FullStats fs
ORDER BY 
    fs.ca_state, fs.cd_gender;
