SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(line.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    lineitem line ON p.p_partkey = line.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA'
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
