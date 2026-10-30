
WITH Customer_Info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_street_address,
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Distinct_Customers AS (
    SELECT DISTINCT 
        full_name, 
        full_street_address, 
        ca_city, 
        ca_state, 
        ca_zip, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
    FROM 
        Customer_Info
    WHERE 
        rn = 1
)
SELECT 
    full_name, 
    full_street_address, 
    CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_location,
    cd_gender, 
    cd_marital_status, 
    cd_education_status
FROM 
    Distinct_Customers
ORDER BY 
    full_name;
