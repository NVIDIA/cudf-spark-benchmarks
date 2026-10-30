
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        COALESCE(NULLIF(CONCAT(c.c_birth_day, '-', c.c_birth_month, '-', c.c_birth_year), '0-0-0'), 'Unknown') AS birth_date,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M' AND 
        cd.cd_marital_status = 'S' AND 
        cd.cd_purchase_estimate > 1000
),
formatted_data AS (
    SELECT
        c_customer_id,
        full_name,
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        total_sales,
        birth_date
    FROM 
        customer_data
)
SELECT 
    *
FROM 
    formatted_data
ORDER BY 
    total_sales DESC,
    full_name ASC
LIMIT 50;
