
WITH Address_Concat AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END, 
                    ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS full_address
    FROM 
        customer_address
), 
Demographics_Filter AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        REPLACE(cd_credit_rating, ' ', '') AS credit_rating_cleaned,
        CONCAT(cd_dep_count, '-', cd_dep_employed_count, '-', cd_dep_college_count) AS dependency_info
    FROM 
        customer_demographics
    WHERE 
        cd_marital_status = 'M' AND cd_gender = 'F'
),
Date_Filter AS (
    SELECT 
        d_date_sk,
        d_date,
        d_day_name,
        d_moy,
        CASE 
            WHEN d_moy IN (1, 2, 12) THEN 'Winter'
            WHEN d_moy IN (3, 4, 5) THEN 'Spring'
            WHEN d_moy IN (6, 7, 8) THEN 'Summer'
            WHEN d_moy IN (9, 10, 11) THEN 'Fall'
        END AS season
    FROM 
        date_dim
    WHERE 
        d_year = 2023
)
SELECT 
    a.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.credit_rating_cleaned,
    d.dependency_info,
    dt.d_day_name,
    dt.season
FROM 
    Address_Concat a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    Demographics_Filter d ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN 
    Date_Filter dt ON dt.d_date_sk = c.c_first_sales_date_sk
ORDER BY 
    a.full_address, d.cd_gender;
