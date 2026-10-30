SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA'
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_cost DESC
LIMIT 10;
