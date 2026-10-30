
WITH string_benchmark AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        LENGTH(c.c_email_address) AS email_length, 
        REPLACE(c.c_email_address, '@', '[at]') AS obfuscated_email,
        SUBSTRING(c.c_last_name FROM 1 FOR 5) AS last_name_prefix,
        UPPER(c.c_first_name) AS upper_first_name,
        c.c_birth_year,
        CAST('2002-10-01' AS DATE) AS d_date,
        CONCAT(c.c_last_name, ', ', c.c_first_name) AS formatted_name,
        LEAST(LENGTH(c.c_first_name), LENGTH(c.c_last_name), LENGTH(c.c_email_address)) AS min_length
    FROM 
        customer c
    JOIN 
        date_dim d ON d.d_date_sk = c.c_first_shipto_date_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
)
SELECT 
    COUNT(*) AS total_rows,
    AVG(email_length) AS avg_email_length,
    COUNT(DISTINCT full_name) AS unique_full_names,
    COUNT(DISTINCT obfuscated_email) AS unique_obfuscated_emails,
    MAX(min_length) AS max_min_length,
    SUM(CASE WHEN upper_first_name LIKE 'A%' THEN 1 ELSE 0 END) AS count_a_names
FROM 
    string_benchmark
GROUP BY 
    c_first_name, 
    c_last_name, 
    email_length, 
    obfuscated_email, 
    last_name_prefix, 
    upper_first_name, 
    c_birth_year, 
    d_date, 
    formatted_name, 
    min_length;
