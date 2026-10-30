SELECT 
    p.p_name, 
    SUM(ls.l_quantity) AS total_quantity, 
    SUM(ls.l_extendedprice) AS total_revenue
FROM 
    part p 
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey 
JOIN 
    supplier s ON ls.l_suppkey = s.s_suppkey 
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
