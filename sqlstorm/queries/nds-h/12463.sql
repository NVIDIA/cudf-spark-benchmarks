SELECT 
    n.n_name,
    r.r_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    revenue DESC;
