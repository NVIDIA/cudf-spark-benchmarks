SELECT 
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    o.o_orderdate,
    c.c_name,
    s.s_name,
    n.n_name
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= '1995-01-01'
GROUP BY 
    l.l_orderkey, o.o_orderdate, c.c_name, s.s_name, n.n_name
ORDER BY 
    revenue DESC
LIMIT 100;
