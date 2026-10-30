
SELECT 
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUBSTRING(c.c_address FROM 1 FOR POSITION(',' IN c.c_address) - 1) AS city,
    p.p_type AS part_type,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
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
    part p ON l.l_partkey = p.p_partkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND
    o.o_orderdate < DATE '1998-01-01' AND 
    p.p_type LIKE '%brass%'
GROUP BY 
    c.c_name, p.p_type, c.c_address
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
