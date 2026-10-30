SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    n.n_name,
    r.r_name
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1997-12-31'
    AND r.r_name = 'Europe'
GROUP BY 
    c.c_name, n.n_name, r.r_name
ORDER BY 
    revenue DESC
LIMIT 10;