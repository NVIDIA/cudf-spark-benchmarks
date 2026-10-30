SELECT 
    n.n_name, 
    sum(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    customer AS c
JOIN 
    orders AS o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem AS l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier AS s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp AS ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    n.n_name
ORDER BY 
    revenue DESC
LIMIT 10;