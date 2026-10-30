
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_day, 
        c.c_birth_month, 
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND ca.ca_state = 'CA'
        AND ca.ca_country = 'USA'
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id, 
        c.full_name, 
        CONCAT(c.c_birth_day, '/', c.c_birth_month, '/', c.c_birth_year) AS birth_date,
        c.cd_gender, 
        c.cd_marital_status, 
        c.cd_education_status, 
        c.ca_city, 
        c.ca_state, 
        c.ca_country
    FROM 
        CustomerData c
    WHERE 
        c.rn = 1
)
SELECT 
    fc.customer_id,
    fc.full_name,
    fc.birth_date,
    fc.cd_gender,
    fc.cd_marital_status,
    fc.cd_education_status,
    fc.ca_city,
    fc.ca_state,
    fc.ca_country,
    LENGTH(fc.full_name) AS name_length,
    UPPER(fc.cd_marital_status) AS marital_status_upper,
    LOWER(fc.cd_education_status) AS education_status_lower
FROM 
    FilteredCustomers fc
ORDER BY 
    fc.ca_city,
    fc.full_name;
