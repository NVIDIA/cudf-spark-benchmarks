
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN ca_city LIKE '%ville%' THEN 1 ELSE 0 END) AS count_ville_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
MergedStats AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.avg_street_name_length,
        a.count_ville_cities,
        c.cd_gender,
        c.customer_count,
        c.avg_purchase_estimate,
        c.total_dependents
    FROM 
        AddressStats a
    CROSS JOIN 
        CustomerStats c
)
SELECT 
    ms.ca_state,
    ms.unique_addresses,
    ms.avg_street_name_length,
    ms.count_ville_cities,
    ms.cd_gender,
    ms.customer_count,
    ms.avg_purchase_estimate,
    ms.total_dependents
FROM 
    MergedStats ms
ORDER BY 
    ms.unique_addresses DESC, ms.customer_count DESC;
