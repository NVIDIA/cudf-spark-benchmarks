SELECT 
    p_brand, 
    AVG(ps_supplycost) AS avg_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p_brand
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;
