SELECT 
    p.p_brand,
    p.p_type,
    p.p_size,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    supplier s ON s.s_suppkey = l.l_suppkey
JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey AND ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    o.o_orderdate >= DATE '1995-01-01' AND 
    o.o_orderdate < DATE '1996-01-01' 
GROUP BY 
    p.p_brand, p.p_type, p.p_size
ORDER BY 
    revenue DESC;
