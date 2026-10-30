SELECT 
    p.p_name,
    s.s_name,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ' supplies part: ', p.p_name) AS supplier_part_info,
    (SELECT COUNT(*) FROM lineitem l 
     WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R') AS return_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LENGTH(p.p_name) > 10 
    AND s.s_acctbal > 1000.00
ORDER BY 
    p.p_name ASC, 
    s.s_name DESC
LIMIT 100;
