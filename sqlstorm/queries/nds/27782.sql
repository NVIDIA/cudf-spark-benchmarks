
WITH string_processing_benchmark AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS lower_full_name,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS upper_full_name,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '-') AS hyphenated_full_name,
        REGEXP_REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), '[^a-zA-Z ]', '') AS cleaned_full_name,
        CASE
            WHEN c.c_first_name LIKE 'A%' THEN 'Starts with A'
            ELSE 'Does not start with A'
        END AS first_name_category
    FROM
        customer c
    WHERE
        c.c_birth_year < 1990
),
length_stats AS (
    SELECT
        AVG(full_name_length) AS avg_length,
        MAX(full_name_length) AS max_length,
        MIN(full_name_length) AS min_length
    FROM
        string_processing_benchmark
)
SELECT
    spb.c_customer_id,
    spb.full_name,
    spb.full_name_length,
    spb.lower_full_name,
    spb.upper_full_name,
    spb.hyphenated_full_name,
    spb.cleaned_full_name,
    spb.first_name_category,
    ls.avg_length,
    ls.max_length,
    ls.min_length
FROM
    string_processing_benchmark spb
JOIN
    length_stats ls ON TRUE
ORDER BY
    spb.full_name_length DESC
LIMIT 100;
