
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        REPLACE(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type), ' ', '-') AS address_formatted,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
Filtered_Customers AS (
    SELECT 
        *
    FROM 
        Ranked_Customers
    WHERE 
        gender_rank <= 10
)
SELECT 
    fc.full_name,
    fc.cd_gender,
    fc.cd_marital_status,
    fc.cd_education_status,
    fc.address_formatted
FROM 
    Filtered_Customers fc
ORDER BY 
    fc.cd_gender, 
    fc.full_name;
