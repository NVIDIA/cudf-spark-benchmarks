SELECT 
    ps.ps_partkey, 
    SUM(ps.ps_availqty) AS total_available, 
    AVG(ps.ps_supplycost) AS average_cost 
FROM 
    partsupp ps 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    r.r_name = 'EUROPE' 
GROUP BY 
    ps.ps_partkey 
ORDER BY 
    total_available DESC 
LIMIT 10;
