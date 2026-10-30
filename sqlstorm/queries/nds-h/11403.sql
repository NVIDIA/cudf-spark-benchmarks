SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_supplycost, 
    ps.ps_availqty, 
    SUM(l.l_quantity) AS total_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, ps.ps_supplycost, ps.ps_availqty
ORDER BY 
    total_quantity DESC
LIMIT 100;
