
WITH string_benchmark AS (
    SELECT 
        c.c_first_name AS customer_first_name,
        c.c_last_name AS customer_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_last_name) AS uppercase_last_name,
        LOWER(c.c_first_name) AS lowercase_first_name,
        LENGTH(c.c_email_address) AS email_length,
        REGEXP_REPLACE(c.c_email_address, '@.*$', '') AS email_prefix,
        REPLACE(c.c_first_name, 'a', '@') AS modified_first_name
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
),
aggregated_stats AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(email_length) AS avg_email_length,
        MIN(email_length) AS min_email_length,
        MAX(email_length) AS max_email_length
    FROM string_benchmark
)
SELECT 
    b.customer_first_name,
    b.customer_last_name,
    b.full_name,
    b.uppercase_last_name,
    b.lowercase_first_name,
    b.email_length,
    b.email_prefix,
    b.modified_first_name,
    a.total_customers,
    a.avg_email_length,
    a.min_email_length,
    a.max_email_length
FROM string_benchmark b, aggregated_stats a
ORDER BY b.customer_last_name ASC;
