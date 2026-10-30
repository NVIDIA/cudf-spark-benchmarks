
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year) AS age_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
CustomerEmails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(c.c_email_address, '@', '[at]') AS email_address,
        CASE 
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Other' 
        END AS marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    re.c_customer_sk,
    re.full_name,
    re.email_address,
    re.marital_status,
    CASE 
        WHEN rc.age_rank <= 5 THEN 'Youngest'
        WHEN rc.age_rank BETWEEN 6 AND 10 THEN 'Middle Age'
        ELSE 'Mature'
    END AS age_group
FROM 
    CustomerEmails re
JOIN 
    RankedCustomers rc ON re.c_customer_sk = rc.c_customer_sk
WHERE 
    rc.age_rank <= 10 AND rc.cd_gender = 'F'
GROUP BY 
    re.c_customer_sk,
    re.full_name,
    re.email_address,
    re.marital_status,
    rc.age_rank
ORDER BY 
    re.full_name ASC;
