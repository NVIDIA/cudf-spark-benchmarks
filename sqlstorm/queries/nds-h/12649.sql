SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_suppkey, 
    s.s_name, 
    sum(l.l_quantity) as total_quantity, 
    sum(l.l_extendedprice) as total_revenue
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_suppkey, 
    s.s_name
ORDER BY 
    total_revenue DESC 
LIMIT 10;
