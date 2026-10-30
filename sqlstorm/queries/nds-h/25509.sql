SELECT 
    p.p_partkey AS part_key,
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    o.o_orderdate AS order_date,
    l.l_quantity AS quantity,
    l.l_extendedprice AS extended_price,
    CONCAT('Supplier: ', s.s_name, ', Customer: ', c.c_name, ', Part: ', p.p_name, ', Order Date: ', CAST(o.o_orderdate AS STRING), ', Quantity: ', CAST(l.l_quantity AS STRING)) AS detailed_info
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
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' 
    AND l.l_returnflag = 'N' 
    AND p.p_retailprice > 100.00
ORDER BY 
    o.o_orderdate ASC, extended_price DESC
LIMIT 100;