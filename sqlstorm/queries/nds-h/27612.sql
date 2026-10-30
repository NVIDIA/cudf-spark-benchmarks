SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    l.l_quantity,
    l.l_extendedprice,
    CONCAT('Supplier: ', s.s_name, ', Customer: ', c.c_name, ', Order: ', o.o_orderkey) AS description,
    LENGTH(p.p_comment) AS comment_length,
    UPPER(p.p_type) AS upper_type,
    TRIM(LEADING 'A' FROM p.p_comment) AS trimmed_comment
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
    p.p_size BETWEEN 1 AND 50
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderstatus = 'O'
ORDER BY 
    p.p_partkey, o.o_orderdate DESC;