WITH String_Processing_Benchmark AS (
    SELECT 
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_info,
        UPPER(p.p_comment) AS upper_part_comment,
        LOWER(s.s_comment) AS lower_supplier_comment,
        LENGTH(p.p_name) AS part_name_length,
        LENGTH(s.s_name) AS supplier_name_length,
        LENGTH(CONCAT(s.s_name, ' ', p.p_name)) AS combined_length
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name LIKE '%land%'
    ORDER BY 
        combined_length DESC
)
SELECT 
    nation_name,
    supplier_name,
    part_name,
    supplier_part_info,
    upper_part_comment,
    lower_supplier_comment,
    part_name_length,
    supplier_name_length,
    combined_length
FROM 
    String_Processing_Benchmark
WHERE 
    part_name_length > 10
    AND supplier_name_length < 20
LIMIT 100;
