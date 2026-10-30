SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Customer: ', c.c_name) AS full_description,
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS average_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count
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
    s.s_comment LIKE '%urgent%'
    AND l.l_shipmode IN ('AIR', 'GROUND')
    AND o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name
ORDER BY 
    total_quantity DESC, average_price DESC
LIMIT 100;