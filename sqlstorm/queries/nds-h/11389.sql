SELECT 
    ps_partkey, 
    SUM(ps_supplycost) AS total_supply_cost, 
    COUNT(DISTINCT ps_suppkey) AS supplier_count
FROM 
    partsupp
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey
JOIN 
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey
WHERE 
    p_size > 10
GROUP BY 
    ps_partkey
ORDER BY 
    total_supply_cost DESC
LIMIT 100;
