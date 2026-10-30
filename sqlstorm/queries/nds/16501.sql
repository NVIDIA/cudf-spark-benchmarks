
SELECT 
    c_first_name, 
    c_last_name, 
    c_email_address 
FROM 
    customer 
WHERE 
    c_birth_year > 1980 
ORDER BY 
    c_last_name;
