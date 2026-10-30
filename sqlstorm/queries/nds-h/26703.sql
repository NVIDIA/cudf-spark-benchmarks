
SELECT 
    p.p_name AS part_name,
    SUBSTR(p.p_comment, 1, 15) AS short_comment,
    s.s_name AS supplier_name,
    CONCAT(s.s_address, ', ', s.s_phone) AS supplier_info,
    COUNT(*) AS total_supplies
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 50.00
    AND s.s_acctbal > 5000.00
GROUP BY 
    p.p_name, p.p_comment, s.s_name, s.s_address, s.s_phone
HAVING 
    COUNT(*) > 10
ORDER BY 
    total_supplies DESC, part_name ASC
LIMIT 20;
