WITH String_Benchmark AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS combined_info,
        LENGTH(CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name)) AS info_length
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    WHERE LENGTH(p.p_name) > 5 AND LENGTH(s.s_name) < 15 AND c.c_mktsegment = 'BUILD'
)
SELECT 
    SUBSTRING(combined_info, 1, 50) AS truncated_info,
    AVG(info_length) AS average_length,
    COUNT(*) AS total_records
FROM String_Benchmark
GROUP BY truncated_info
ORDER BY average_length DESC
LIMIT 10;
