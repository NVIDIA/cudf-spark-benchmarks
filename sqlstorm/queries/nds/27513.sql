
WITH Address_Statistics AS (
    SELECT 
        CA.ca_state,
        COUNT(DISTINCT CA.ca_address_sk) AS unique_addresses,
        AVG(LENGTH(CA.ca_street_name)) AS avg_street_name_length,
        SUM(CASE WHEN CA.ca_street_type IS NOT NULL THEN 1 ELSE 0 END) AS street_type_count,
        MAX(LENGTH(CA.ca_city)) AS max_city_length
    FROM 
        customer_address CA
    GROUP BY 
        CA.ca_state
),
Customer_Demo_Statistics AS (
    SELECT 
        CD.cd_gender,
        COUNT(DISTINCT CD.cd_demo_sk) AS total_demographics,
        AVG(CD.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CD.cd_dep_count) AS total_dependents,
        COUNT(CASE WHEN CD.cd_marital_status = 'M' THEN 1 END) AS married_count
    FROM 
        customer_demographics CD
    GROUP BY 
        CD.cd_gender
),
Combined_Statistics AS (
    SELECT 
        A.ca_state,
        A.unique_addresses,
        A.avg_street_name_length,
        A.street_type_count,
        A.max_city_length,
        C.cd_gender,
        C.total_demographics,
        C.avg_purchase_estimate,
        C.total_dependents,
        C.married_count
    FROM 
        Address_Statistics A
    JOIN 
        Customer_Demo_Statistics C ON A.ca_state = C.cd_gender
)
SELECT 
    CS.ca_state,
    MAX(CS.unique_addresses) AS max_addresses,
    AVG(CS.avg_street_name_length) AS overall_avg_street_name_length,
    SUM(CS.street_type_count) AS total_street_types,
    MAX(CS.max_city_length) AS overall_max_city_length,
    SUM(CS.total_demographics) AS overall_demographic_count,
    AVG(CS.avg_purchase_estimate) AS avg_purchase,
    SUM(CS.total_dependents) AS total_dependents,
    SUM(CS.married_count) AS total_married
FROM 
    Combined_Statistics CS
GROUP BY 
    CS.ca_state
ORDER BY 
    overall_avg_street_name_length DESC;
