WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        c.c_name,
        CONCAT('Part: ', p.p_name, ' (', p.p_partkey, ') - Supplier: ', s.s_name) AS part_supplier_info,
        REPLACE(p.p_comment, 't', 'z') AS modified_comment,
        LENGTH(p.p_name) AS name_length,
        LOWER(p.p_name) AS lower_name,
        UPPER(s.s_name) AS upper_supplier_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    WHERE 
        p.p_size BETWEEN 1 AND 25 
        AND LENGTH(p.p_comment) > 15
        AND LOWER(s.s_name) LIKE '%inc%'
)
SELECT 
    part_supplier_info,
    modified_comment,
    name_length,
    lower_name,
    upper_supplier_name
FROM 
    StringProcessing
ORDER BY 
    name_length DESC;
