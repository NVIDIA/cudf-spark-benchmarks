SELECT 
    p_brand, 
    COUNT(*) AS supplier_count, 
    SUM(ps_supplycost) AS total_supply_cost 
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey 
JOIN 
    supplier ON ps_suppkey = s_suppkey 
GROUP BY 
    p_brand 
ORDER BY 
    total_supply_cost DESC 
LIMIT 10;
