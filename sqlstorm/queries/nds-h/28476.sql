SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    o.o_orderdate,
    CONCAT('Order ID: ', o.o_orderkey, ' - Part: ', p.p_name, ' (', p.p_size, ' units) from Supplier: ', s.s_name) AS detailed_info,
    REPLACE(UPPER(o.o_comment), 'ORDER', 'TRANSACTION') AS modified_comment,
    LENGTH(p.p_comment) AS comment_length
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
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate <= '1997-12-31' AND 
    p.p_size BETWEEN 5 AND 15
ORDER BY 
    o.o_orderdate DESC, 
    p.p_name ASC;