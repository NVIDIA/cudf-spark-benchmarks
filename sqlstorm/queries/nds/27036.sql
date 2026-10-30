
WITH Address_Stats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY')
    GROUP BY 
        ca_city, ca_state
),
Demographics_Aggregate AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
Combined_Stats AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.address_count,
        a.unique_addresses,
        a.avg_street_name_length,
        a.max_street_name_length,
        d.cd_gender,
        d.cd_marital_status,
        d.total_purchase_estimate,
        d.avg_dependents,
        d.highest_credit_rating
    FROM 
        Address_Stats a
    JOIN 
        Demographics_Aggregate d ON a.ca_state IN (SELECT ca_state FROM customer_address)
)
SELECT 
    ca_city,
    ca_state,
    address_count,
    unique_addresses,
    avg_street_name_length,
    max_street_name_length,
    cd_gender,
    cd_marital_status,
    total_purchase_estimate,
    avg_dependents,
    highest_credit_rating
FROM 
    Combined_Stats
ORDER BY 
    address_count DESC, total_purchase_estimate DESC
LIMIT 100;
