SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    l.l_quantity AS quantity,
    l.l_extendedprice AS extended_price,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Customer: ', c.c_name) AS detailed_info,
    LEFT(l.l_comment, 20) AS comment_excerpt,
    LENGTH(c.c_address) AS address_length,
    UPPER(p.p_comment) AS upper_case_comment
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
    LENGTH(p.p_comment) > 10
    AND s.s_acctbal > 1000
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    l.l_extendedprice DESC
LIMIT 50;