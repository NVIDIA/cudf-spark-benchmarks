SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    SUM(ps.ps_supplycost) AS total_supply_cost, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand 
ORDER BY 
    total_orders DESC
LIMIT 100;
