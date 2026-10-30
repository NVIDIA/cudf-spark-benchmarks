SELECT 
    p.p_name, 
    s.s_name, 
    n.n_name AS supplier_nation,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
    LEFT(p.p_comment, 15) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name) AS supplier_info
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE 'widget%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, c.c_name, o.o_orderkey, o.o_orderdate, p.p_comment
ORDER BY 
    total_price DESC
LIMIT 10;