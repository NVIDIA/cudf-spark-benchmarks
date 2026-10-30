SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    r.r_name = 'ASIA'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
ORDER BY 
    total_revenue DESC
LIMIT 10;
