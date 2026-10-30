SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    sum(ps.ps_availqty) as total_available_quantity, 
    sum(ps.ps_supplycost * ps.ps_availqty) as total_supply_cost 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_name 
ORDER BY 
    total_supply_cost DESC 
LIMIT 10;
