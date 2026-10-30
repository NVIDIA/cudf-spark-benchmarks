SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    SUM(lp.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem lp ON ps.ps_partkey = lp.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
