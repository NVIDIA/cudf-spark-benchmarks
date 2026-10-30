
WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(p.p_name, ' ', p.p_comment) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' ', p.p_comment)) AS total_length,
        SUBSTR(p.p_name, 1, 10) AS name_part,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        REPLACE(p.p_comment, 'fragile', 'durable') AS modified_comment,
        TRIM(p.p_comment) AS trimmed_comment,
        CHAR_LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE LENGTH(p.p_name) > 0
),
AggregatedLengths AS (
    SELECT 
        AVG(total_length) AS avg_length,
        MAX(comment_length) AS max_comment_length,
        MIN(comment_length) AS min_comment_length
    FROM StringBenchmark
)
SELECT 
    'Part Count' AS metric,
    COUNT(*) AS value
FROM StringBenchmark
UNION ALL
SELECT 
    'Average Length of Combined String' AS metric,
    avg_length
FROM AggregatedLengths
UNION ALL
SELECT 
    'Maximum Comment Length' AS metric,
    max_comment_length
FROM AggregatedLengths
UNION ALL
SELECT 
    'Minimum Comment Length' AS metric,
    min_comment_length
FROM AggregatedLengths
ORDER BY metric;
