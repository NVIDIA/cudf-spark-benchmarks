
WITH customer_full_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY c.c_birth_year DESC) AS age_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ranked_customers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY age_rank) AS customer_rank
    FROM 
        customer_full_details
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_country
FROM 
    ranked_customers
WHERE 
    customer_rank <= 5
ORDER BY 
    ca_state, 
    full_name;
