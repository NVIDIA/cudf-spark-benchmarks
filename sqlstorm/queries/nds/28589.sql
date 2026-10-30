
WITH AddressAnalysis AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(*) AS total_addresses,
        SUM(CASE 
            WHEN ca_street_name IS NOT NULL AND LENGTH(TRIM(ca_street_name)) > 0 THEN 1 
            ELSE 0 
        END) AS valid_street_names,
        AVG(CASE 
            WHEN ca_street_name IS NOT NULL AND LENGTH(TRIM(ca_street_name)) > 0 THEN LENGTH(ca_street_name)
            ELSE NULL 
        END) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerAnalysis AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE 
            WHEN cd_credit_rating LIKE '%Good%' THEN 1
            ELSE 0 
        END) AS good_credit_count,
        SUM(CASE 
            WHEN cd_marital_status = 'M' THEN 1 
            ELSE 0 
        END) AS married_count
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
CombinedAnalysis AS (
    SELECT 
        aa.ca_state, 
        aa.unique_cities, 
        aa.total_addresses, 
        aa.valid_street_names, 
        aa.avg_street_name_length,
        ca.cd_gender,
        ca.total_customers,
        ca.avg_purchase_estimate,
        ca.good_credit_count,
        ca.married_count
    FROM 
        AddressAnalysis aa
    JOIN 
        CustomerAnalysis ca ON aa.ca_state IN (SELECT ca_state FROM customer_address)
)
SELECT 
    ca_state,
    SUM(total_addresses) AS total_addresses,
    SUM(unique_cities) AS total_unique_cities,
    AVG(avg_purchase_estimate) AS avg_purchase_estimate_per_state,
    SUM(valid_street_names) AS total_valid_street_names,
    AVG(avg_street_name_length) AS avg_street_name_length,
    SUM(married_count) AS total_married_customers,
    SUM(good_credit_count) AS total_good_credit_customers
FROM 
    CombinedAnalysis
GROUP BY 
    ca_state
ORDER BY 
    total_addresses DESC;
