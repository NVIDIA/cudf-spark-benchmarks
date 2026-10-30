
WITH String_Benchmark AS (
    SELECT
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '') AS full_name_without_spaces,
        LENGTH(REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '')) AS full_name_without_spaces_length,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_lower,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_upper,
        LEFT(CONCAT(c.c_first_name, ' ', c.c_last_name), 10) AS full_name_first_10_chars,
        RIGHT(CONCAT(c.c_first_name, ' ', c.c_last_name), 10) AS full_name_last_10_chars,
        SUBSTRING(CONCAT(c.c_first_name, ' ', c.c_last_name), 6, 5) AS full_name_substring
    FROM
        customer c
    WHERE
        c.c_first_name IS NOT NULL AND c.c_last_name IS NOT NULL
),
Aggregated_Results AS (
    SELECT
        AVG(full_name_length) AS avg_full_name_length,
        AVG(full_name_without_spaces_length) AS avg_full_name_without_spaces_length,
        COUNT(*) AS total_records
    FROM
        String_Benchmark
)
SELECT
    a.avg_full_name_length,
    a.avg_full_name_without_spaces_length,
    a.total_records,
    (SELECT COUNT(*) FROM customer) AS total_customers,
    (SELECT COUNT(DISTINCT CONCAT(c_first_name, ' ', c_last_name)) FROM customer) AS unique_full_names,
    (SELECT COUNT(DISTINCT c_email_address) FROM customer) AS unique_emails
FROM
    Aggregated_Results a;
