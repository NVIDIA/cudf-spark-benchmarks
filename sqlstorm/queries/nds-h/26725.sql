SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    SUBSTRING(p.p_comment, 1, 20) AS part_comment,
    CONCAT('Supplier: ', s.s_name, ', Comment: ', SUBSTRING(s.s_comment, 1, 30)) AS supplier_info,
    LENGTH(o.o_comment) AS order_comment_length,
    COUNT(l.l_orderkey) AS total_lineitems
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
    p.p_brand LIKE 'Brand%'
    AND s.s_acctbal > 1000.00
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, p.p_comment, s.s_comment, o.o_comment
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    total_lineitems DESC, part_name ASC;