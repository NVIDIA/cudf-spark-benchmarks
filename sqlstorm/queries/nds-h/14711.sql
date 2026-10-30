SELECT 
    n.n_name,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS revenue
FROM 
    lineitem AS lp
JOIN 
    orders AS o ON lp.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
JOIN 
    nation AS n ON c.c_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= DATE '1995-01-01' 
    AND o.o_orderdate < DATE '1996-01-01'
GROUP BY 
    n.n_name
ORDER BY 
    revenue DESC;
