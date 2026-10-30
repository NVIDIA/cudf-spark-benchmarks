SELECT 
    n.n_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    orders AS o
JOIN 
    lineitem AS l ON o.o_orderkey = l.l_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
JOIN 
    nation AS n ON c.c_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;