WITH EnhancedCustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_month,
        c.c_birth_day,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(CONCAT(ca.ca_city, ', ', ca.ca_state)) AS full_address,
        EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year AS age
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    full_name,
    age,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    COUNT(*) OVER (PARTITION BY cd_marital_status ORDER BY age) AS marital_status_count
FROM 
    EnhancedCustomerInfo
WHERE 
    age BETWEEN 18 AND 65
ORDER BY 
    age DESC, 
    full_name;