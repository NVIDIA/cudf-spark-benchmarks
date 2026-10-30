SELECT 
    p_brand,
    SUM(ps_supplycost * ps_availqty) AS total_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p_brand
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
