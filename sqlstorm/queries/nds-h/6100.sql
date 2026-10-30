SELECT 
    n.n_name AS nation_name, 
    r.r_name AS region_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(l.l_quantity) AS average_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
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
    l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC, unique_customers DESC, average_quantity DESC
LIMIT 10;