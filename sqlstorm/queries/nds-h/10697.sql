SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    s.s_name AS supplier_name,
    n.n_name AS nation_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;