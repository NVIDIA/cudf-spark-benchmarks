SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ' - ', p.p_comment) AS detailed_comment,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    AND p.p_size BETWEEN 10 AND 20
    AND o.o_orderdate > '1994-01-01'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, order_count ASC;