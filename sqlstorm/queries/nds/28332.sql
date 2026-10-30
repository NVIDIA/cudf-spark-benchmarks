
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Filtered_Customers AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status
    FROM 
        Ranked_Customers rc
    WHERE 
        rc.rank <= 10
),
Customer_Addresses AS (
    SELECT
        ca.ca_address_id,
        ca.ca_street_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city ILIKE '%New%' AND
        ca.ca_state = 'CA'
)
SELECT 
    fc.c_customer_id,
    fc.c_first_name,
    fc.c_last_name,
    fc.cd_gender,
    fc.cd_marital_status,
    fc.cd_education_status,
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip
FROM 
    Filtered_Customers fc
LEFT JOIN 
    Customer_Addresses ca ON fc.c_customer_id = ca.ca_address_id
ORDER BY 
    fc.c_last_name, fc.c_first_name;
