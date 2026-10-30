SELECT 
    CONCAT('Part Name: ', p_name, ' | Supplier: ', s_name, ' | Nation: ', n_name) AS detailed_info,
    LENGTH(p_comment) AS comment_length,
    UPPER(s_comment) AS upper_supplier_comment,
    LOWER(p_type) AS normalized_part_type,
    REPLACE(s_address, 'Street', 'St.') AS short_address
FROM 
    part
JOIN 
    partsupp ON p_partkey = ps_partkey
JOIN 
    supplier ON ps_suppkey = s_suppkey
JOIN 
    nation ON s_nationkey = n_nationkey
WHERE 
    LENGTH(p_name) > 10
    AND s_acctbal > 5000
ORDER BY 
    comment_length DESC
LIMIT 10;
