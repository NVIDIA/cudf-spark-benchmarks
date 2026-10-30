SELECT 
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate,
    c.c_nationkey,
    n.n_name,
    r.r_name
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
    l.l_shipdate >= DATE '1995-01-01'
    AND l.l_shipdate < DATE '1996-01-01'
GROUP BY 
    l.l_orderkey, o.o_orderdate, c.c_nationkey, n.n_name, r.r_name
ORDER BY 
    revenue DESC;
