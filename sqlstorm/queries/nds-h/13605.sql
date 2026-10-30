SELECT 
    p.p_partkey, 
    p.p_name, 
    COUNT(ps.ps_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    SUM(l.l_extendedprice) AS total_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_extended_price DESC
LIMIT 100;
