
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT(c.c_name, ' from ', s.s_address) AS customer_supplier_info,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    p.p_size IN (10, 20, 30) 
    AND s.s_acctbal > 1000.00
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, s.s_address
HAVING 
    COUNT(o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
