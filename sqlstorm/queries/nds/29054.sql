
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
),
TrimmedEmails AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        TRIM(UPPER(c_email_address)) AS trimmed_email
    FROM 
        RankedCustomers
    WHERE 
        gender_rank <= 20
),
EmailCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS email_count
    FROM 
        TrimmedEmails
    GROUP BY 
        cd_gender
)
SELECT 
    ec.cd_gender,
    ec.email_count,
    REPLACE(e.full_name, ' ', '%') AS wildcard_full_name
FROM 
    EmailCounts ec
JOIN 
    TrimmedEmails e ON ec.cd_gender = e.cd_gender
ORDER BY 
    ec.cd_gender;
