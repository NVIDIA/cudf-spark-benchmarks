SELECT 
    n.n_name, 
    SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'F'
GROUP BY 
    n.n_name
ORDER BY 
    total_cost DESC;
