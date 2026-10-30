SELECT 
    n.r_name AS region, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    region n
JOIN 
    nation r ON n.r_regionkey = r.n_regionkey
JOIN 
    supplier s ON r.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    n.r_regionkey, n.r_name
ORDER BY 
    total_revenue DESC;