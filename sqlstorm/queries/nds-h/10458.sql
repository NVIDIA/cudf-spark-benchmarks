
SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    avg_supply_cost DESC
LIMIT 50;
