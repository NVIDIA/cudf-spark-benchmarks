
WITH  string_benchmark AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        SUBSTRING(CONCAT(c.c_first_name, ' ', c.c_last_name), 1, 10) AS name_preview,
        CASE 
            WHEN LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) > 20 THEN 'Long Name'
            ELSE 'Short Name'
        END AS name_length_category,
        ROW_NUMBER() OVER (PARTITION BY c.c_birth_year ORDER BY c.c_last_name) AS name_rank
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT 
    sb.c_customer_sk,
    sb.full_name,
    sb.full_name_length,
    sb.name_preview,
    sb.name_length_category,
    COUNT(*) OVER (PARTITION BY sb.name_length_category) AS category_count,
    MAX(sb.name_rank) OVER (PARTITION BY sb.name_length_category) AS max_rank_in_category
FROM string_benchmark AS sb
WHERE sb.name_length_category = 'Long Name'
ORDER BY sb.full_name_length DESC
LIMIT 100;
