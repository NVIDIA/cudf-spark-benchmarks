SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_supplycost, 
    SUM(l.l_quantity) AS total_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_supplycost
ORDER BY 
    total_quantity DESC
LIMIT 100;