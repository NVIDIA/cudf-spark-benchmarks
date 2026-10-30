
WITH StringBenchmark AS (
    SELECT 
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_name) AS name_lower,
        CONCAT(p.p_name, ' - ', p.p_comment) AS name_comment_combined,
        REPLACE(p.p_comment, 'specified', 'replaced') AS comment_modified,
        TRIM(p.p_comment) AS comment_trimmed,
        SUBSTRING(p.p_comment, 1, 10) AS comment_substring,
        CHAR_LENGTH(p.p_name) AS char_length
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container = 'BOX')
)
SELECT 
    name_length,
    COUNT(*) AS total_parts,
    COUNT(DISTINCT name_upper) AS distinct_name_upper,
    COUNT(DISTINCT name_lower) AS distinct_name_lower,
    COUNT(DISTINCT name_comment_combined) AS distinct_comment_combined,
    COUNT(DISTINCT comment_modified) AS distinct_comment_modified,
    AVG(char_length) AS avg_character_length
FROM 
    StringBenchmark
GROUP BY 
    name_length
ORDER BY 
    name_length DESC;
