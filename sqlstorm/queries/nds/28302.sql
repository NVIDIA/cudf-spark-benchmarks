
WITH processed_customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        c.c_birth_month,
        c.c_birth_day,
        c.c_birth_year,
        (EXTRACT(YEAR FROM DATE '2002-10-01') - c.c_birth_year) AS age
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
age_distribution AS (
    SELECT 
        CASE 
            WHEN age < 20 THEN 'Under 20'
            WHEN age BETWEEN 20 AND 29 THEN '20-29'
            WHEN age BETWEEN 30 AND 39 THEN '30-39'
            WHEN age BETWEEN 40 AND 49 THEN '40-49'
            WHEN age BETWEEN 50 AND 59 THEN '50-59'
            WHEN age >= 60 THEN '60 and over'
        END AS age_group,
        COUNT(*) AS count
    FROM 
        processed_customer_info
    GROUP BY 
        age_group
)
SELECT 
    age_group,
    count,
    (count * 100.0 / (SELECT COUNT(*) FROM processed_customer_info)) AS percentage
FROM 
    age_distribution
ORDER BY 
    CASE age_group
        WHEN 'Under 20' THEN 1
        WHEN '20-29' THEN 2
        WHEN '30-39' THEN 3
        WHEN '40-49' THEN 4
        WHEN '50-59' THEN 5
        WHEN '60 and over' THEN 6
        ELSE 7
    END;
