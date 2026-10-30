SELECT 
    ps.ps_partkey, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers 
FROM 
    partsupp ps 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
WHERE 
    p.p_retailprice > 100.00 
GROUP BY 
    ps.ps_partkey 
ORDER BY 
    total_available_quantity DESC 
LIMIT 10;
