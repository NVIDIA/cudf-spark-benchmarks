
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_last_name, c.c_first_name) AS rn
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city LIKE 'San%' AND
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
), FilteredCustomers AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        ca_city,
        ca_state,
        COUNT(*) OVER (PARTITION BY ca_state) AS total_in_state
    FROM 
        RankedCustomers
    WHERE 
        rn <= 10
)
SELECT 
    ca_state,
    COUNT(*) AS number_of_customers,
    AVG(total_in_state) AS avg_customers_per_state
FROM 
    FilteredCustomers
GROUP BY 
    ca_state
ORDER BY 
    number_of_customers DESC;
