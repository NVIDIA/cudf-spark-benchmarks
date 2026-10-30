
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank_by_age
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA'
),
AggregatedData AS (
    SELECT 
        full_name, 
        cd_gender, 
        ca_city,
        rank_by_age
    FROM 
        RankedCustomers
    WHERE 
        rank_by_age <= 10
)
SELECT 
    COUNT(*) AS top_customers_count,
    cd_gender,
    ca_city
FROM 
    AggregatedData
GROUP BY 
    cd_gender, 
    ca_city
ORDER BY 
    top_customers_count DESC, 
    ca_city;
