SELECT 
    n.n_name AS nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA' 
    AND o.o_orderdate >= DATE '1994-01-01' 
    AND o.o_orderdate < DATE '1995-01-01'
GROUP BY 
    n.n_name
ORDER BY 
    revenue DESC;
