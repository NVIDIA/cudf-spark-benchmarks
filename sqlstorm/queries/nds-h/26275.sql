WITH StringBenchmark AS (
    SELECT 
        p_name,
        LENGTH(p_name) AS name_length,
        UPPER(p_name) AS name_upper,
        LOWER(p_name) AS name_lower,
        TRIM(p_name) AS name_trimmed,
        REPLACE(p_name, ' ', '-') AS name_replaced,
        SUBSTRING(p_name FROM 1 FOR 10) AS name_substring,
        CONCAT('Part: ', p_name) AS name_concatenated
    FROM part
),
GroupedResults AS (
    SELECT 
        SUBSTRING(name_concatenated FROM 1 FOR 8) AS short_name,
        COUNT(*) AS count,
        AVG(name_length) AS avg_length,
        MAX(name_length) AS max_length,
        MIN(name_length) AS min_length
    FROM StringBenchmark
    GROUP BY short_name
)
SELECT 
    short_name,
    count,
    avg_length,
    max_length,
    min_length
FROM GroupedResults
WHERE count > 1
ORDER BY avg_length DESC, count ASC;
