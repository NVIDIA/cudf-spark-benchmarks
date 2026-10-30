SELECT 
    p.p_partkey, 
    p.p_name, 
    COUNT(ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_supplycost) AS total_supply_cost, 
    AVG(l.l_extendedprice) AS avg_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_supply_cost DESC
LIMIT 100;
