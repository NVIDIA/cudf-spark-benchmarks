
WITH StringProcessing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_email_address) AS upper_email,
        LOWER(c.c_first_name) AS lower_first_name,
        REPLACE(c.c_last_name, ' ', '-') AS last_name_hyphenated,
        LENGTH(c.c_email_address) AS email_length,
        CASE 
            WHEN POSITION('.' IN c.c_email_address) > 0 THEN 'Valid Email'
            ELSE 'Invalid Email'
        END AS email_status
    FROM customer c
    WHERE c.c_first_name IS NOT NULL
      AND c.c_last_name IS NOT NULL
)
SELECT 
    sp.full_name,
    sp.upper_email,
    sp.lower_first_name,
    sp.last_name_hyphenated,
    sp.email_length,
    sp.email_status,
    COUNT(w.w_warehouse_id) AS warehouse_count
FROM StringProcessing sp
LEFT JOIN warehouse w ON MOD(sp.email_length, 10) = MOD(w.w_warehouse_sk, 10)  
GROUP BY 
    sp.full_name, 
    sp.upper_email, 
    sp.lower_first_name, 
    sp.last_name_hyphenated, 
    sp.email_length, 
    sp.email_status
ORDER BY sp.email_length DESC, sp.full_name;
