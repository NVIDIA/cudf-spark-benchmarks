SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;