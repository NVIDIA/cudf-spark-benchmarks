SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    n_name AS nation_name,
    o_orderdate
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    o_orderdate >= '1996-01-01' AND o_orderdate < '1997-01-01'
GROUP BY 
    n_name, o_orderdate
ORDER BY 
    total_revenue DESC;