SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    p.p_brand AS brand,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    CONCAT('Total quantity for ', p.p_name, ' by ', s.s_name, ' is ', SUM(ps.ps_availqty)) AS detailed_comment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.s_name, p.p_name, p.p_brand
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
