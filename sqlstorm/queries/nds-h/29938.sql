SELECT 
    CONCAT('Supplier Name: ', s.s_name, ' | Nation: ', n.n_name, 
           ' | Product: ', p.p_name, ' | Comment: ', ps.ps_comment) AS detailed_info,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(distinct o.o_orderkey) AS total_orders
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    s.s_comment LIKE '%reliable%' 
    AND p.p_size BETWEEN 10 AND 50
GROUP BY 
    s.s_name, n.n_name, p.p_name, ps.ps_comment
ORDER BY 
    total_orders DESC, average_supply_cost ASC
LIMIT 10;
