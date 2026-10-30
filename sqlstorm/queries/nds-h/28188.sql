SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    CONCAT(s.s_address, ', ', n.n_name) AS supplier_location,
    SUM(l.l_quantity) AS total_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_name LIKE '%widget%' 
    AND l.l_shipdate >= '1997-01-01' 
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    s.s_address, 
    n.n_name
ORDER BY 
    total_quantity DESC
LIMIT 10;