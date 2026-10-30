SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA'
GROUP BY 
    p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
