SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    CONCAT('Supplier ', s.s_name, ' has provided ', p.p_size, ' units of ', p.p_name) AS supplier_info,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_shipdate > '1997-01-01') AS recent_shipments,
    REPLACE(s.s_address, ' ', '_') AS formatted_address
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    o.o_orderstatus = 'O' 
    AND p.p_retailprice BETWEEN 50.00 AND 200.00
ORDER BY 
    o.o_orderdate DESC
LIMIT 100;