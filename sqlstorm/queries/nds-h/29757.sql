SELECT 
    CONCAT('Supplier Name: ', s.s_name, ', Part: ', p.p_name, ', Comment: ', ps.ps_comment) AS detailed_info,
    LENGTH(s.s_name) AS supplier_name_length,
    LENGTH(p.p_name) AS part_name_length,
    LENGTH(ps.ps_comment) AS comment_length,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    REPLACE(s.s_comment, 'excellent', 'superb') AS modified_comment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 100.00
AND 
    s.s_acctbal < (SELECT AVG(s2.s_acctbal) FROM supplier s2)
ORDER BY 
    p.p_name ASC, s.s_name DESC
LIMIT 50;
