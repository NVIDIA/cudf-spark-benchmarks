
WITH StringBenchmark AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS combined_string,
        LENGTH(CONCAT(s.s_name, ' supplies ', p.p_name)) AS string_length,
        UPPER(CONCAT(s.s_name, ' supplies ', p.p_name)) AS upper_case_string,
        LOWER(CONCAT(s.s_name, ' supplies ', p.p_name)) AS lower_case_string,
        REPLACE(CONCAT(s.s_name, ' supplies ', p.p_name), ' ', '_') AS replaced_string
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        LENGTH(s.s_name) > 10 AND 
        LENGTH(p.p_name) < 30
),
FinalBenchmark AS (
    SELECT 
        supplier_name,
        part_name,
        string_length,
        CHAR_LENGTH(upper_case_string) AS upper_case_length,
        CHAR_LENGTH(lower_case_string) AS lower_case_length,
        CHAR_LENGTH(replaced_string) AS replaced_string_length
    FROM 
        StringBenchmark
    ORDER BY 
        string_length DESC
)
SELECT 
    supplier_name,
    part_name,
    string_length,
    upper_case_length,
    lower_case_length,
    replaced_string_length
FROM 
    FinalBenchmark
WHERE 
    string_length > 50
LIMIT 100;
