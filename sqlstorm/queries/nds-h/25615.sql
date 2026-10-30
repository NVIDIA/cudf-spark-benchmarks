WITH  string_benchmark AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' - ', p.p_mfgr, ': ', p.p_comment) AS benchmark_string
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
    UNION ALL
    SELECT 
        s.s_suppkey AS p_partkey,
        CONCAT(s.s_name, ' - ', s.s_address, ': ', SUBSTRING(s.s_comment, 1, 15)) AS benchmark_string
    FROM 
        supplier s
    WHERE 
        s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
)
SELECT 
    COUNT(DISTINCT benchmark_string) AS unique_string_count,
    MAX(LENGTH(benchmark_string)) AS max_string_length,
    MIN(LENGTH(benchmark_string)) AS min_string_length,
    AVG(LENGTH(benchmark_string)) AS avg_string_length
FROM 
    string_benchmark;
