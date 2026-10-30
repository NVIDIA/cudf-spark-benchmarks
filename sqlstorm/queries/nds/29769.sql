
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS locality_info,
        UPPER(ca_country) AS country_uppercase
    FROM 
        customer_address
),
CustomerOverview AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.full_address,
        ca.locality_info,
        ca.country_uppercase,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    COUNT(*) AS total_customers,
    COUNT(DISTINCT full_name) AS unique_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    cd_gender,
    cd_marital_status
FROM 
    CustomerOverview
GROUP BY 
    cd_gender,
    cd_marital_status
ORDER BY 
    cd_gender ASC,
    cd_marital_status ASC;
