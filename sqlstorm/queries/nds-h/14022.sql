SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available,
    AVG(ps.ps_supplycost) AS average_supply_cost 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
GROUP BY 
    p.p_name, s.s_name 
ORDER BY 
    total_available DESC 
LIMIT 100;
