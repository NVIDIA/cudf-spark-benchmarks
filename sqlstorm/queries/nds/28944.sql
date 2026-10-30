
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AgeDistribution AS (
    SELECT 
        EXTRACT(YEAR FROM '2002-10-01' :: DATE) - c_birth_year AS age,
        COUNT(*) AS count
    FROM 
        CustomerData
    GROUP BY 
        age
),
EducationDistribution AS (
    SELECT 
        cd_education_status,
        COUNT(*) AS count
    FROM 
        CustomerData
    GROUP BY 
        cd_education_status
),
GenderDistribution AS (
    SELECT 
        cd_gender,
        COUNT(*) AS count
    FROM 
        CustomerData
    GROUP BY 
        cd_gender
)
SELECT 
    'Age Distribution' AS category,
    CAST(age AS STRING) AS value,
    count
FROM 
    AgeDistribution

UNION ALL

SELECT 
    'Education Distribution' AS category,
    cd_education_status AS value,
    count
FROM 
    EducationDistribution

UNION ALL

SELECT 
    'Gender Distribution' AS category,
    cd_gender AS value,
    count
FROM 
    GenderDistribution
ORDER BY 
    category, value;
