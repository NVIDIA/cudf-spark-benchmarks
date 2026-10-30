WITH StringBenchmark AS (
    SELECT 
        p.p_name,
        CONCAT('Supplier: ', s.s_name, ' | Comment: ', ps.ps_comment) AS supplier_info,
        REPLACE(REPLACE(LOWER(p.p_comment), ' ', '_'), '!', '') AS sanitized_comment,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(s.s_address, 1, 20) AS short_address,
        TRIM(BOTH ' ' FROM s.s_phone) AS formatted_phone,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey 
    LEFT JOIN 
        lineitem l ON l.l_partkey = p.p_partkey 
    LEFT JOIN 
        orders o ON o.o_orderkey = l.l_orderkey 
    GROUP BY 
        p.p_name, s.s_name, ps.ps_comment, p.p_comment, s.s_address, s.s_phone
)

SELECT 
    p_name, 
    supplier_info, 
    sanitized_comment, 
    name_length, 
    short_address, 
    formatted_phone, 
    order_count 
FROM 
    StringBenchmark 
WHERE 
    order_count > 0 
ORDER BY 
    name_length DESC, 
    order_count DESC 
LIMIT 10;
