
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        full_name, 
        ca_city, 
        ca_state, 
        cd_gender, 
        cd_marital_status
    FROM 
        RankedCustomers
    WHERE 
        city_rank <= 10
)
SELECT 
    ca_city AS city, 
    ca_state AS state, 
    cd_gender AS gender, 
    COUNT(*) AS number_of_customers,
    ARRAY_AGG(full_name) AS customer_names
FROM 
    FilteredCustomers
GROUP BY 
    ca_city, ca_state, cd_gender
ORDER BY 
    number_of_customers DESC, ca_city;
