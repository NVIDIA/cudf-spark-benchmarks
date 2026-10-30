SELECT 
    n.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS profit
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
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
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    profit DESC;