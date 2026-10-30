
SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', From Nation: ', n.n_name) AS detail_description,
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    UPPER(p.p_comment) AS upper_case_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%widget%' AND 
    s.s_address LIKE '%Street%' AND 
    o.o_orderdate BETWEEN '1995-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 50 
ORDER BY 
    total_orders DESC, average_supply_cost ASC;
