
WITH StringManipulation AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS full_customer_name,
        ca.ca_city,
        CASE 
            WHEN LENGTH(c.c_email_address) < 30 THEN c.c_email_address 
            ELSE SUBSTR(c.c_email_address, 1, 30) || '...' 
        END AS truncated_email,
        REPLACE(REPLACE(ca.ca_street_name, ' St', ''), ' Ave', '') AS cleaned_street_name,
        CONCAT(CONCAT(UPPER(SUBSTR(ca.ca_state, 1, 1)), LOWER(SUBSTR(ca.ca_state, 2))), ' - ', ca.ca_zip) AS state_zip_combination
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL 
        AND c.c_first_name IS NOT NULL
)
SELECT 
    full_customer_name,
    ca_city,
    truncated_email,
    cleaned_street_name,
    state_zip_combination
FROM 
    StringManipulation
ORDER BY 
    full_customer_name ASC
LIMIT 100;
