
WITH  string_benchmark AS (
    SELECT 
        p_name AS original_string,
        UPPER(p_name) AS upper_case,
        LOWER(p_name) AS lower_case,
        LENGTH(p_name) AS string_length,
        REPLACE(p_name, ' ', '-') AS hyphenated_string,
        SUBSTRING(p_name FROM 1 FOR 10) AS substring,
        CONCAT(p_name, ' - ', p_comment) AS concatenated_string,
        CHAR_LENGTH(p_name) AS char_length
    FROM 
        part
), aggregated_results AS (
    SELECT
        COUNT(*) AS total_parts,
        AVG(string_length) AS avg_length,
        MAX(string_length) AS max_length,
        MIN(string_length) AS min_length,
        SUM(CASE WHEN original_string LIKE '%A%' THEN 1 ELSE 0 END) AS count_with_A,
        SUM(CASE WHEN original_string LIKE '%B%' THEN 1 ELSE 0 END) AS count_with_B,
        SUM(CASE WHEN original_string LIKE '%C%' THEN 1 ELSE 0 END) AS count_with_C
    FROM 
        string_benchmark
)
SELECT 
    total_parts,
    avg_length,
    max_length,
    min_length,
    count_with_A,
    count_with_B,
    count_with_C
FROM 
    aggregated_results;
