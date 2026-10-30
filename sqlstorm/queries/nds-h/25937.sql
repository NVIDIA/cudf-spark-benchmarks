
SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    CONCAT('Supplier ', s.s_suppkey, ': ', s.s_name) AS full_supplier_info,
    CONCAT('Part ', p.p_partkey, ': ', p.p_name, ' from ', s.s_name) AS full_part_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    MAX(l.l_discount) AS max_discount
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%widget%'
    AND s.s_acctbal > 1000
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, p.p_partkey, s.s_suppkey
ORDER BY 
    total_quantity DESC, average_price ASC
LIMIT 10;
