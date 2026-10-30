
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
FilteredCustomers AS (
    SELECT 
        r.full_name,
        r.cd_gender,
        r.cd_marital_status,
        r.cd_education_status
    FROM 
        RankedCustomers r
    WHERE 
        r.rn <= 10
)
SELECT 
    CONCAT(fc.full_name, ' - ', CASE 
        WHEN fc.cd_marital_status = 'M' THEN 'Married' 
        ELSE 'Single' END) AS customer_profile,
    fc.cd_gender,
    fc.cd_education_status,
    COUNT(*) OVER (PARTITION BY fc.cd_gender, fc.cd_marital_status) AS gender_marital_count
FROM 
    FilteredCustomers fc
ORDER BY 
    fc.cd_gender, fc.cd_marital_status, fc.full_name;
