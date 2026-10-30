SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity_sold, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderdate,
    n.n_name AS nation_name
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderstatus = 'F'
    AND l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'EUROPE')
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, o.o_orderdate, n.n_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_revenue DESC;