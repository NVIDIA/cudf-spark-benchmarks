SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' supplies ', p.p_name) AS supplier_details,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(o.o_totalprice) AS min_order_total,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%wood%'
    AND n.n_name IN (SELECT n2.n_name FROM nation n2 WHERE n2.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))
GROUP BY 
    s.s_name, n.n_name, p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
