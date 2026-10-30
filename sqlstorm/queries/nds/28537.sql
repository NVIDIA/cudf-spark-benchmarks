
WITH StringBenchmark AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        CASE 
            WHEN LENGTH(c.c_first_name) > LENGTH(c.c_last_name) THEN 'First name is longer'
            WHEN LENGTH(c.c_first_name) < LENGTH(c.c_last_name) THEN 'Last name is longer'
            ELSE 'Names are of equal length'
        END AS name_length_comparison,
        REGEXP_REPLACE(c.c_email_address, '@.*$', '') AS email_username,
        wp.wp_url AS web_page_url,
        LPAD(c.c_customer_id, 16, '0') AS padded_customer_id
    FROM 
        customer c
    JOIN 
        web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE 
        c.c_first_name IS NOT NULL 
        AND c.c_last_name IS NOT NULL
        AND c.c_email_address IS NOT NULL
    ORDER BY 
        c.c_customer_id
)
SELECT 
    full_name, 
    first_name_length, 
    last_name_length, 
    name_length_comparison, 
    email_username, 
    web_page_url, 
    padded_customer_id
FROM 
    StringBenchmark
WHERE 
    LENGTH(email_username) BETWEEN 5 AND 15
ORDER BY 
    first_name_length DESC;
