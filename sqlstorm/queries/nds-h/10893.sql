SELECT 
    n.n_name,
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue
FROM 
    lineitem ls
JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    ls.l_shipdate >= DATE '1995-01-01' AND 
    ls.l_shipdate < DATE '1996-01-01'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;
