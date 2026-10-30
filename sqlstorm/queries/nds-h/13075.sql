SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_revenue 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
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
