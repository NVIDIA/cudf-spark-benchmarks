SELECT 
    p.p_name, 
    COUNT(*) AS supplier_count, 
    SUM(ps.ps_supplycost) AS total_supply_cost 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
GROUP BY 
    p.p_name 
ORDER BY 
    supplier_count DESC 
LIMIT 10;
