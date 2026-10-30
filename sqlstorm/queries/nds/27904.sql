
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        d.d_date AS birth_date,
        da.full_address,
        da.city,
        da.state,
        da.zip
    FROM 
        customer c
    JOIN 
        address_parts da ON c.c_current_addr_sk = da.ca_address_sk
    JOIN 
        date_dim d ON c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy AND c.c_birth_year = d.d_year
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ci.full_name,
        ci.birth_date,
        ci.full_address,
        ci.city,
        ci.state,
        ci.zip
    FROM 
        customer_demographics cd
    JOIN 
        customer_info ci ON cd.cd_demo_sk = ci.c_customer_sk
)
SELECT 
    d.full_name,
    d.birth_date,
    d.city,
    d.state,
    d.zip,
    CASE 
        WHEN d.cd_gender = 'M' THEN 'Male'
        WHEN d.cd_gender = 'F' THEN 'Female'
        ELSE 'Other' 
    END AS gender,
    COUNT(CASE 
        WHEN d.cd_marital_status = 'M' THEN 1 
    END) AS married_count,
    AVG(d.cd_purchase_estimate) AS avg_purchase_estimation
FROM 
    demographics d
GROUP BY 
    d.full_name, d.birth_date, d.city, d.state, d.zip, d.cd_gender
ORDER BY 
    avg_purchase_estimation DESC
LIMIT 100;
