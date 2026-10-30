
SELECT 
    p.p_name, 
    s.s_name, 
    n.n_name, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info,
    REPLACE(p.p_comment, 'old', 'new') AS updated_comment,
    LENGTH(p.p_name) AS part_name_length,
    CHAR_LENGTH(s.s_name) AS supplier_name_length 
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    s.s_acctbal > 1000.00 
AND 
    p.p_size BETWEEN 10 AND 50
GROUP BY 
    p.p_name, 
    s.s_name, 
    n.n_name, 
    updated_comment, 
    part_name_length, 
    supplier_name_length
ORDER BY 
    part_name_length DESC, 
    supplier_name_length ASC
LIMIT 10;
