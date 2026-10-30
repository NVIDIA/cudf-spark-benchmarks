SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
ORDER BY 
    total_available_quantity DESC
LIMIT 100;
