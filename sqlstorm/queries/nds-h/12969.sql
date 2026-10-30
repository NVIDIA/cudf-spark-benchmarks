SELECT 
    p_brand, 
    AVG(ps_supplycost) AS avg_supply_cost, 
    COUNT(DISTINCT s_suppkey) AS supplier_count 
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey 
JOIN 
    supplier ON ps_suppkey = s_suppkey 
GROUP BY 
    p_brand 
ORDER BY 
    avg_supply_cost DESC 
LIMIT 10;
