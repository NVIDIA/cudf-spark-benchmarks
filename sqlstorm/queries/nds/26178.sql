
WITH address_counts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(ca_address_id) AS total_addresses,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length,
        SUM(LENGTH(ca_city)) AS total_city_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(CASE WHEN cd_marital_status = 'M' THEN 1 END) AS married_count,
        COUNT(CASE WHEN cd_marital_status = 'S' THEN 1 END) AS single_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
merged_data AS (
    SELECT 
        ac.ca_state,
        ac.unique_addresses,
        ac.total_addresses,
        ac.total_street_name_length,
        ac.total_city_length,
        ds.cd_gender,
        ds.total_demographics,
        ds.avg_purchase_estimate,
        ds.married_count,
        ds.single_count
    FROM 
        address_counts ac
    JOIN 
        demographic_summary ds 
    ON 
        SUBSTRING(ac.ca_state FROM 1 FOR 1) = SUBSTRING(ds.cd_gender FROM 1 FOR 1
    )
)
SELECT 
    ca_state,
    unique_addresses,
    total_addresses,
    total_street_name_length,
    total_city_length,
    cd_gender,
    total_demographics,
    avg_purchase_estimate,
    married_count,
    single_count
FROM 
    merged_data
ORDER BY 
    ca_state;
