WITH  customer_income AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_first_name) AS row_num
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
age_summary AS (
    SELECT 
        c.c_customer_sk,
        (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) AS age,
        COUNT(*) OVER (PARTITION BY (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year)) AS count_same_age
    FROM 
        customer c
)
SELECT 
    ci.c_customer_sk,
    ci.income_band,
    ci.cd_gender,
    ci.cd_marital_status,
    age_summary.age,
    age_summary.count_same_age,
    CASE 
        WHEN ci.cd_credit_rating IS NULL THEN 'Unknown' 
        ELSE ci.cd_credit_rating 
    END AS credit_rating,
    COALESCE(CONCAT(ci.cd_gender, ' - ', ci.cd_marital_status), 'N/A') AS gender_marital_status,
    CASE 
        WHEN age_summary.age IS NULL THEN 'Not Applicable'
        WHEN age_summary.age < 30 THEN 'Youth'
        WHEN age_summary.age BETWEEN 30 AND 60 THEN 'Adult'
        ELSE 'Senior'
    END AS age_category
FROM 
    customer_income ci
FULL OUTER JOIN 
    age_summary ON ci.c_customer_sk = age_summary.c_customer_sk
WHERE 
    (ci.cd_gender = 'F' OR ci.cd_gender IS NULL)
    AND ci.income_band > 0
    AND (age_summary.age IS NOT NULL OR ci.row_num = 1)
ORDER BY 
    age_category, ci.income_band DESC;