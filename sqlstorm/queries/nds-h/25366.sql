SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderdate AS order_date,
    l.l_quantity AS quantity,
    l.l_extendedprice AS extended_price,
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name, ', Order Date: ', CAST(o.o_orderdate AS STRING), ', Quantity: ', CAST(l.l_quantity AS STRING), ', Extended Price: ', CAST(l.l_extendedprice AS STRING)) AS detailed_info
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderpriority = 'HIGH'
    AND l.l_shipmode IN ('AIR', 'SHIP')
    AND SUBSTRING(p.p_comment, 1, 5) = 'frag'
ORDER BY 
    order_date DESC, extended_price DESC
LIMIT 100;
