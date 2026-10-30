SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name, 
    COUNT(*) AS supply_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ' - Total Available: ', SUM(ps.ps_availqty)) AS detailed_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%metal%' 
    AND s.s_acctbal > 1000 
    AND LENGTH(s.s_comment) > 50
GROUP BY 
    p.p_name, s.s_name
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_available_quantity DESC;
