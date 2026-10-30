SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_cost DESC
LIMIT 10;
