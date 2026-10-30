SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_cost DESC
LIMIT 10;
