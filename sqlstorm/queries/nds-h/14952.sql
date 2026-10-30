SELECT 
    n.n_name, 
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_supplycost DESC
LIMIT 10;
