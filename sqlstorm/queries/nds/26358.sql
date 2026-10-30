
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
filtered_customers AS (
    SELECT 
        *,
        LENGTH(full_name) AS name_length,
        UPPER(full_name) AS name_upper,
        LOWER(full_name) AS name_lower,
        REPLACE(full_name, ' ', '-') AS name_hyphenated
    FROM 
        ranked_customers
    WHERE 
        gender_rank <= 10
),
customer_info AS (
    SELECT 
        fC.c_customer_id,
        fC.full_name,
        fC.cd_gender,
        fC.cd_marital_status,
        fC.cd_education_status,
        fC.name_length,
        fC.name_upper,
        fC.name_lower,
        fC.name_hyphenated,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        filtered_customers fC
    JOIN 
        customer_address ca ON fC.c_customer_id = ca.ca_address_id
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.name_length,
    ci.name_upper,
    ci.name_lower,
    ci.name_hyphenated,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip
FROM 
    customer_info ci
WHERE 
    ci.cd_marital_status = 'M'
ORDER BY 
    ci.name_length DESC;
