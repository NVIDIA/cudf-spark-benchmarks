
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT('Supplier:', s.s_name, ', Part:', p.p_name) AS supplier_part_info,
    SUBSTRING(p.p_comment, 1, POSITION(' ' IN p.p_comment) - 1) AS truncated_part_comment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    LENGTH(s.s_name) > 10 
    AND p.p_retailprice > 50.00 
GROUP BY 
    s.s_name, p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC;
