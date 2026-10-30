WITH StringBenchmark AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS combined_info,
        LENGTH(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name)) AS string_length,
        UPPER(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name)) AS upper_info,
        LOWER(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name)) AS lower_info,
        REPLACE(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name), ' ', '-') AS replaced_info,
        SUBSTRING(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name), 1, 20) AS substring_info
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    MAX(string_length) AS max_length,
    MIN(string_length) AS min_length,
    AVG(string_length) AS avg_length,
    COUNT(DISTINCT upper_info) AS distinct_upper,
    COUNT(DISTINCT lower_info) AS distinct_lower,
    COUNT(DISTINCT replaced_info) AS distinct_replaced,
    COUNT(DISTINCT substring_info) AS distinct_substrings
FROM 
    StringBenchmark;
