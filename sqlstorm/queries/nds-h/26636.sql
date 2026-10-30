SELECT 
    CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_name,
    LENGTH(CONCAT(s.s_name, ' - ', p.p_name)) AS name_length,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    REPLACE(p.p_type, 'type', 'category') AS modified_type,
    UPPER(s.s_address) AS upper_address,
    (SELECT COUNT(*) FROM supplier WHERE s_nationkey = s.s_nationkey) AS total_suppliers_in_nation
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > 5000 AND
    (p.p_comment LIKE '%fragile%' OR p.p_comment LIKE '%urgent%')
ORDER BY 
    name_length DESC, 
    upper_address
LIMIT 100;
