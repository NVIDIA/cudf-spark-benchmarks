
WITH StringProcessing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS birth_rank,
        LENGTH(c.c_email_address) AS email_length,
        UPPER(c.c_first_name) AS upper_first_name,
        LOWER(c.c_last_name) AS lower_last_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year > 2000
)
SELECT 
    full_name,
    full_address,
    birth_rank,
    email_length,
    upper_first_name,
    lower_last_name
FROM 
    StringProcessing
WHERE 
    birth_rank <= 5
ORDER BY 
    email_length DESC, full_name;
