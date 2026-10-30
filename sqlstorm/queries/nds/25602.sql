
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    UPPER(full_name) AS customer_name,
    LOWER(cd_gender) AS gender,
    CASE 
        WHEN cd_marital_status = 'S' THEN 'Single'
        WHEN cd_marital_status = 'M' THEN 'Married'
        ELSE 'Other'
    END AS marital_status,
    INITCAP(cd_education_status) AS education_status,
    CONCAT(ca_city, ', ', ca_state) AS location,
    COUNT(*) OVER() AS total_customers
FROM 
    CustomerData
WHERE 
    rn = 1
ORDER BY 
    full_name;
