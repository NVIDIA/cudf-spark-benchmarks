SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    CONCAT('Supplier: ', s.s_name, ', Total Parts: ', COUNT(DISTINCT p.p_partkey), ', Available Quantity: ', SUM(ps.ps_availqty), ', Avg Cost: ', ROUND(AVG(ps.ps_supplycost), 2)) AS supplier_summary
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.s_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_available_quantity DESC;
