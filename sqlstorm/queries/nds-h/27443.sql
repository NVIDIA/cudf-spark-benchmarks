
WITH StringStats AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS combined_string,
        LENGTH(CONCAT(s.s_name, ' supplies ', p.p_name)) AS string_length,
        UPPER(CONCAT(s.s_name, ' supplies ', p.p_name)) AS uppercased_string,
        LOWER(CONCAT(s.s_name, ' supplies ', p.p_name)) AS lowercased_string,
        REPLACE(CONCAT(s.s_name, ' supplies ', p.p_name), ' ', '-') AS hyphenated_string,
        CHAR_LENGTH(CONCAT(s.s_name, ' supplies ', p.p_name)) AS char_length
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        LENGTH(s.s_name) > 10
        AND LENGTH(p.p_name) > 10
)
SELECT 
    supplier_name,
    part_name,
    COUNT(*) AS occurrences,
    AVG(string_length) AS avg_length,
    MAX(string_length) AS max_length,
    MIN(string_length) AS min_length,
    SUM(string_length) AS total_length
FROM 
    StringStats
GROUP BY 
    supplier_name, part_name
ORDER BY 
    occurrences DESC, avg_length DESC
LIMIT 100;
