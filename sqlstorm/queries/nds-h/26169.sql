WITH StringProcessing AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name) AS combined_info,
        LENGTH(p.p_name) AS part_name_length,
        UPPER(s.s_name) AS upper_supplier_name,
        LOWER(p.p_name) AS lower_part_name,
        REPLACE(p.p_comment, 'special', 'ordinary') AS modified_comment,
        TRIM(s.s_address) AS trimmed_address
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
)
SELECT 
    supplier_name,
    part_name,
    combined_info,
    part_name_length,
    upper_supplier_name,
    lower_part_name,
    modified_comment,
    trimmed_address
FROM 
    StringProcessing
WHERE 
    part_name_length > 10
ORDER BY 
    part_name_length DESC, supplier_name;
