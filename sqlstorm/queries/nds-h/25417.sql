SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    SUBSTRING(p.p_comment, 1, 20) AS short_comment, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS detailed_info,
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
    LENGTH(p.p_name) > 10
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    comment_length DESC, 
    o.o_orderdate ASC
LIMIT 50;