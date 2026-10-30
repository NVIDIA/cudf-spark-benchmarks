
WITH String_Processing AS (
    SELECT 
        DISTINCT 
        CONCAT(UPPER(c.c_first_name), ' ', LOWER(c.c_last_name)) AS full_name,
        REGEXP_REPLACE(REPLACE(c.c_email_address, '@', ' [AT] '), '\..*$', ' [DOT]') AS sanitized_email,
        SUBSTRING(c.c_birth_country, 1, 3) AS country_code,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr.'
            WHEN cd.cd_gender = 'F' THEN 'Ms.'
            ELSE 'Mx.'
        END AS salutation,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS name_length,
        COALESCE(NULLIF(ca.ca_city, ''), 'Unknown') AS address_city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    full_name,
    sanitized_email,
    country_code,
    salutation,
    name_length,
    address_city
FROM 
    String_Processing
WHERE 
    name_length > 10
ORDER BY 
    name_length DESC, full_name
LIMIT 100;
