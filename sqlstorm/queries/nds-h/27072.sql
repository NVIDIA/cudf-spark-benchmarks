SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderdate AS order_date, 
    l.l_quantity AS quantity_sold, 
    l.l_extendedprice AS extended_price, 
    CONCAT('Order from ', c.c_name, ' with total price ', o.o_totalprice) AS order_details,
    REPLACE(REPLACE(p.p_comment, 'common', 'uncommon'), 'new', 'old') AS modified_comment,
    LENGTH(p.p_comment) AS comment_length,
    TRIM(BOTH ' ' FROM p.p_mfgr) AS trimmed_manufacturer
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
    p.p_size > 10 AND 
    l.l_returnflag = 'N' AND 
    c.c_mktsegment = 'BUILDING'
ORDER BY 
    order_date DESC, extended_price DESC
LIMIT 100;
