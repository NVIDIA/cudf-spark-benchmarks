
WITH CustomerFullName AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        c.c_birth_month,
        c.c_birth_day,
        c.c_birth_year
    FROM 
        customer c
), Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
), AggregatedData AS (
    SELECT 
        cf.full_name,
        cf.c_email_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        COUNT(DISTINCT cf.c_birth_year) AS birth_years_count,
        AVG(d.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        CustomerFullName cf
    JOIN 
        Demographics d ON cf.c_customer_sk = d.cd_demo_sk
    GROUP BY 
        cf.full_name, cf.c_email_address, d.cd_gender, d.cd_marital_status, d.cd_education_status
)
SELECT 
    ad.full_name,
    ad.c_email_address,
    ad.cd_gender,
    ad.cd_marital_status,
    ad.avg_purchase_estimate,
    CONCAT(ad.cd_gender, ' - ', ad.cd_marital_status) AS gender_marital_status,
    CASE 
        WHEN ad.birth_years_count > 1 THEN 'Multiple Birth Years'
        ELSE 'Single Birth Year'
    END AS birth_years_status
FROM 
    AggregatedData ad
WHERE 
    ad.avg_purchase_estimate > 1000
ORDER BY 
    ad.avg_purchase_estimate DESC
LIMIT 50;
