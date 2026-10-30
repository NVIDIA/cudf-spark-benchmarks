
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressCount AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
PopularCities AS (
    SELECT 
        ca_city, 
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY address_count DESC) AS city_rank
    FROM 
        AddressCount
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating
FROM 
    CustomerInfo ci
JOIN 
    PopularCities pc ON ci.ca_city = pc.ca_city AND ci.ca_state = pc.ca_state
WHERE 
    pc.city_rank <= 3
ORDER BY 
    ci.ca_state, pc.city_rank;
