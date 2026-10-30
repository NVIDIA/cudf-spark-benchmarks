SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    s.s_acctbal, 
    SUM(l.l_extendedprice) AS total_revenue 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, s.s_acctbal 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
