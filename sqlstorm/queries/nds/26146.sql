
WITH CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY LENGTH(c.c_first_name) + LENGTH(c.c_last_name) DESC) AS name_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) > 10
),
AddressRanked AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(*) AS address_count,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY COUNT(*) DESC) AS address_rank
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
    HAVING 
        COUNT(*) > 1
)
SELECT 
    cr.c_customer_sk,
    cr.c_first_name,
    cr.c_last_name,
    ar.ca_city,
    ar.ca_state,
    ar.ca_country,
    ar.address_count
FROM 
    CustomerRanked cr
JOIN 
    AddressRanked ar ON cr.name_rank <= 3 AND ar.address_rank <= 5
ORDER BY 
    cr.name_rank, ar.address_count DESC
LIMIT 100;
