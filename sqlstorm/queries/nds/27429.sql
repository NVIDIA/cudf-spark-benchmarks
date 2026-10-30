
WITH processed_strings AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        INITCAP(c.c_email_address) AS formatted_email,
        REPLACE(c.c_login, 'user', 'customer') AS modified_login,
        LENGTH(c.c_email_address) AS email_length,
        CASE 
            WHEN c.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
            WHEN c.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
            WHEN c.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END AS birth_quarter
    FROM 
        customer c
),
customer_summary AS (
    SELECT 
        p.full_name,
        p.formatted_email,
        p.modified_login,
        p.email_length,
        p.birth_quarter,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        processed_strings p 
    JOIN 
        customer_demographics cd ON p.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    birth_quarter,
    COUNT(*) AS customer_count,
    AVG(email_length) AS avg_email_length,
    COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count,
    COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_count,
    COUNT(CASE WHEN cd_marital_status = 'M' THEN 1 END) AS married_count
FROM 
    customer_summary
GROUP BY 
    birth_quarter
ORDER BY 
    birth_quarter;
