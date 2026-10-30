SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    l.l_quantity AS quantity,
    l.l_extendedprice AS extended_price,
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Customer: ', c.c_name, ' | Order: ', o.o_orderkey) AS description
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
    p.p_retailprice > 50.00 
    AND s.s_acctbal > 1000.00 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    extended_price DESC
LIMIT 100;