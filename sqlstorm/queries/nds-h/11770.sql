SELECT 
    n.n_name, 
    r.r_name, 
    COUNT(DISTINCT c.c_custkey) AS custdist, 
    SUM(o.o_totalprice) AS revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= DATE '1995-01-01' 
    AND o.o_orderdate < DATE '1996-01-01'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    r.r_name, n.n_name;
