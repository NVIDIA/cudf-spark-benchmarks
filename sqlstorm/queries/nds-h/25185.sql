WITH String_Benchmark AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        CONCAT(s.s_name, ' - ', p.p_name) AS combined_info,
        LENGTH(p.p_comment) AS comment_length,
        REGEXP_REPLACE(LOWER(p.p_comment), '[^a-z]', '') AS cleaned_comment,
        COUNT(s.s_suppkey) OVER (PARTITION BY p.p_partkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    part_name,
    supplier_name,
    short_comment,
    combined_info,
    comment_length,
    cleaned_comment,
    supplier_count
FROM 
    String_Benchmark
WHERE 
    LENGTH(cleaned_comment) > 5
ORDER BY 
    supplier_count DESC, comment_length DESC
LIMIT 100;
