
WITH AddressDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        LENGTH(ca.ca_street_name) AS street_name_length,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL AND 
        ca.ca_state IS NOT NULL AND 
        ca.ca_country IS NOT NULL
),
DemographicDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
),
JoinedDetails AS (
    SELECT 
        ad.full_name,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        dm.cd_gender,
        dm.cd_marital_status,
        dm.cd_education_status,
        dm.cd_purchase_estimate,
        ad.street_name_length,
        ad.full_name_length
    FROM 
        AddressDetails ad
    JOIN 
        DemographicDetails dm ON ad.c_customer_sk = dm.cd_demo_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    street_name_length,
    full_name_length,
    CONCAT(UPPER(SUBSTRING(full_name FROM 1 FOR 1)), LOWER(SUBSTRING(full_name FROM 2))) AS formatted_full_name
FROM 
    JoinedDetails
WHERE 
    cd_purchase_estimate > 1000
ORDER BY 
    full_name_length DESC, 
    ca_city ASC;
