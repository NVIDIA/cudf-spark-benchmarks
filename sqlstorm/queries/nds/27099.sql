
WITH processed_addresses AS (
    SELECT 
        ca_city,
        ca_state,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_street_name) AS upper_street_name,
        LOWER(ca_street_name) AS lower_street_name,
        REPLACE(ca_street_name, ' ', '_') AS underscore_street_name,
        TRIM(ca_street_name) AS trimmed_street_name
    FROM 
        customer_address
), 
customer_demographics_stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
address_demographic_combined AS (
    SELECT 
        p.ca_city,
        p.ca_state,
        p.ca_country,
        c.cd_gender AS ds_gender,
        c.total_customers,
        c.avg_dependents,
        c.total_purchase_estimate
    FROM 
        processed_addresses p
    JOIN 
        customer_demographics_stats c ON p.ca_state = 'CA'
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.ca_country,
    a.ds_gender,
    a.total_customers,
    a.avg_dependents,
    a.total_purchase_estimate,
    CONCAT(a.ca_city, ', ', a.ca_state, ', ', a.ca_country) AS full_address,
    COUNT(DISTINCT a.ds_gender) AS unique_gender_count
FROM 
    address_demographic_combined a
GROUP BY 
    a.ca_city, a.ca_state, a.ca_country, a.ds_gender, a.total_customers, a.avg_dependents, a.total_purchase_estimate
ORDER BY 
    a.ca_city, a.total_purchase_estimate DESC
LIMIT 100;
