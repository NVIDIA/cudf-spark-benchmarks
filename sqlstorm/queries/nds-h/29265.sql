
SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' [', s.s_address, ']'), '; ') AS supplier_details,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_supplycost) AS min_supply_cost,
    SUM(CASE WHEN POSITION('fragile' IN ps.ps_comment) > 0 THEN ps.ps_supplycost ELSE 0 END) AS total_fragile_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%metal%' 
    AND s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
