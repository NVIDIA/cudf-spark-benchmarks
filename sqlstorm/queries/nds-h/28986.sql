
WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        CONCAT(p.p_name, ' supplied by ', s.s_name) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' supplied by ', s.s_name)) AS string_length,
        CHAR_LENGTH(p.p_comment) AS comment_length,
        UPPER(p.p_mfgr) AS upper_mfgr,
        LOWER(s.s_name) AS lower_supplier,
        LPAD(s.s_phone, 15, '0') AS formatted_phone,
        REPLACE(p.p_comment, 'tiny', 'large') AS modified_comment
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    COUNT(*) AS total_strings,
    AVG(string_length) AS avg_string_length,
    MAX(string_length) AS max_string_length,
    MIN(string_length) AS min_string_length,
    SUM(CHAR_LENGTH(modified_comment)) AS total_modified_comment_length,
    upper_mfgr
FROM StringBenchmark
WHERE string_length > 40
GROUP BY upper_mfgr
ORDER BY total_strings DESC;
