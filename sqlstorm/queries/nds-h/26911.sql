SELECT 
    substr(c.c_name, 1, 10) AS cust_name_prefix,
    p.p_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    MAX(l.l_extendedprice) AS max_extended_price,
    AVG(l.l_discount) AS avg_discount
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    c.c_acctbal > 1000
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND p.p_type LIKE '%cotton%'
GROUP BY 
    cust_name_prefix, p.p_name, supplier_name
ORDER BY 
    total_orders DESC, total_quantity ASC
LIMIT 100;