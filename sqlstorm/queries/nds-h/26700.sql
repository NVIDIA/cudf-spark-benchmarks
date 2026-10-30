SELECT 
    p.p_name,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info,
    LENGTH(p.p_comment) AS comment_length,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    UPPER(p.p_mfgr) AS mfgr_uppercase,
    TRIM(p.p_container) AS trimmed_container,
    REPLACE(p.p_comment, 'outdated', 'updated') AS updated_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LENGTH(s.s_name) > 5 AND 
    p.p_size BETWEEN 10 AND 20
ORDER BY 
    comment_length DESC, 
    supplier_part_info ASC
LIMIT 50;
