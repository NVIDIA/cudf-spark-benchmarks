
WITH string_benchmark AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        LOWER(c.c_email_address) AS lower_email,
        UPPER(c.c_email_address) AS upper_email,
        REPLACE(c.c_email_address, '@', '[at]') AS obfuscated_email,
        LEFT(c.c_email_address, POSITION('@' IN c.c_email_address) - 1) AS email_prefix,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
),
name_statistics AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(first_name_length) AS avg_first_name_length,
        AVG(last_name_length) AS avg_last_name_length,
        COUNT(DISTINCT full_name) AS distinct_full_names
    FROM 
        string_benchmark
)
SELECT 
    n.total_customers,
    n.avg_first_name_length,
    n.avg_last_name_length,
    n.distinct_full_names,
    MAX(s.full_name) AS max_full_name,
    MIN(s.full_name) AS min_full_name
FROM 
    name_statistics n
JOIN 
    string_benchmark s ON LENGTH(s.full_name) > 15
GROUP BY 
    n.total_customers, n.avg_first_name_length, n.avg_last_name_length, n.distinct_full_names;
