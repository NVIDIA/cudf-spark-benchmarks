SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(ps.ps_supplycost) AS avg_supply_cost 
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
GROUP BY 
    p.p_name 
ORDER BY 
    total_quantity DESC 
LIMIT 10;
