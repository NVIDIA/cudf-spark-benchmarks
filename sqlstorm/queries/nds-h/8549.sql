SELECT 
    n.n_name AS nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(distinct o.o_orderkey) AS total_orders
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'EUROPE' AND
    o.o_orderdate >= DATE '1995-01-01' AND
    o.o_orderdate < DATE '1996-01-01'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
