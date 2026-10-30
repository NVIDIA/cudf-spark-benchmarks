
WITH StringProcessing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS upper_full_name,
        LENGTH(c.c_email_address) AS email_length,
        REPLACE(c.c_email_address, '@', '[at]') AS modified_email,
        SUBSTRING(c.c_first_name, 1, 1) AS first_initial,
        CASE 
            WHEN cd.cd_gender = 'M' THEN CONCAT('Mr. ', c.c_last_name) 
            ELSE CONCAT('Ms. ', c.c_last_name) 
        END AS salutation
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        LENGTH(c.c_first_name) > 3
)
SELECT 
    full_name,
    upper_full_name,
    email_length,
    modified_email,
    first_initial,
    salutation
FROM 
    StringProcessing
ORDER BY 
    email_length DESC
LIMIT 100;
