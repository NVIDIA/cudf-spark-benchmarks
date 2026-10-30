WITH  string_benchmarks AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' - ', p.p_mfgr) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' - ', p.p_mfgr)) AS str_length,
        SUBSTRING(CONCAT(p.p_name, ' - ', p.p_mfgr), 1, 20) AS substring,
        UPPER(CONCAT(p.p_name, ' - ', p.p_mfgr)) AS upper_string,
        LOWER(CONCAT(p.p_name, ' - ', p.p_mfgr)) AS lower_string
    FROM part p
    WHERE p.p_size > 10
),
final_benchmark AS (
    SELECT 
        sb.p_partkey,
        sb.combined_string,
        sb.str_length,
        sb.substring,
        sb.upper_string,
        sb.lower_string,
        COUNT(*) OVER() AS total_count
    FROM string_benchmarks sb
)
SELECT 
    p.p_partkey, 
    p.combined_string, 
    p.str_length,
    p.substring, 
    p.upper_string, 
    p.lower_string,
    ROUND(AVG(p.str_length) OVER(), 2) AS average_length,
    COUNT(DISTINCT p.upper_string) AS unique_upper_count,
    COUNT(*) AS total_rows
FROM final_benchmark p
GROUP BY p.p_partkey, p.combined_string, p.str_length, p.substring, p.upper_string, p.lower_string
ORDER BY p.str_length DESC
LIMIT 100;
