
WITH StringBenchmarks AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        UPPER(c.c_first_name) AS upper_first_name,
        LOWER(c.c_last_name) AS lower_last_name,
        SUBSTRING(c.c_email_address, 1, 10) AS email_prefix,
        REPLACE(c.c_email_address, '@', '[at]') AS email_modified,
        TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS trimmed_name,
        CASE 
            WHEN c.c_birth_month BETWEEN 1 AND 6 THEN 'First Half'
            ELSE 'Second Half'
        END AS birth_half,
        ROW_NUMBER() OVER (ORDER BY LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) DESC) AS ranking
    FROM 
        customer c
    WHERE 
        c.c_preferred_cust_flag = 'Y' 
        AND c.c_email_address IS NOT NULL
)
SELECT 
    sb.full_name,
    sb.name_length,
    sb.upper_first_name,
    sb.lower_last_name,
    sb.email_prefix,
    sb.email_modified,
    sb.trimmed_name,
    sb.birth_half,
    sb.ranking
FROM 
    StringBenchmarks sb
WHERE 
    sb.name_length > 20
ORDER BY 
    sb.name_length DESC
LIMIT 100;
