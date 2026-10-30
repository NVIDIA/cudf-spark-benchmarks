SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey AND ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name = 'GERMANY'
GROUP BY 
    p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
