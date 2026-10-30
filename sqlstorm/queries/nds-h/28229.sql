SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    l.l_quantity,
    l.l_discount,
    CONCAT('Supplier: ', s.s_name, ', Customer: ', c.c_name, ', Part: ', p.p_name, ', Order Date: ', CAST(o.o_orderdate AS STRING), ', Quantity: ', CAST(l.l_quantity AS STRING)) AS detailed_info
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND l.l_discount > 0.1
ORDER BY 
    o.o_orderdate DESC, l.l_quantity DESC
LIMIT 100;