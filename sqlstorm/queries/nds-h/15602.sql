SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
ORDER BY 
    total_quantity DESC
LIMIT 10;
