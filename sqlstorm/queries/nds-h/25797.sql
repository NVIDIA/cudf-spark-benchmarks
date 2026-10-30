SELECT 
    CONCAT(SUBSTRING(p.p_name, 1, 20), '...', SUBSTRING(p.p_name, LENGTH(p.p_name) - 19, 20)) AS truncated_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_mktsegment = 'BUILDING'
    AND (p.p_comment LIKE '%copper%' OR p.p_comment LIKE '%steel%')
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_orders DESC, average_discount ASC
LIMIT 10;
