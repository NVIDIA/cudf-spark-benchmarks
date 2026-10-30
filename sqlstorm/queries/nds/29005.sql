
SELECT 
    c.c_first_name,
    c.c_last_name,
    LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_lower,
    UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_upper,
    LENGTH(c.c_email_address) AS email_length,
    LPAD(c.c_birth_country, 20, '*') AS masked_birth_country,
    REPLACE(c.c_email_address, '@', ' AT ') AS email_with_replacement,
    CASE 
        WHEN cd_gender = 'M' THEN 'Male'
        WHEN cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description,
    ca_state AS state_from_address,
    COUNT(DISTINCT ws_order_number) AS order_count
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    LENGTH(c.c_email_address) > 5 
    AND c.c_first_name IS NOT NULL 
GROUP BY 
    c.c_first_name, c.c_last_name, cd_gender, ca_state, c.c_email_address, c.c_birth_country
HAVING 
    COUNT(DISTINCT ws_order_number) > 2
ORDER BY 
    full_name_lower ASC;
