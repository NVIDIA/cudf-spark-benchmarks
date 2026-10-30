SELECT 
    c.c_custkey, 
    c.c_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    customer AS c
JOIN 
    orders AS o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem AS l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderdate >= DATE '1995-01-01' 
    AND o.o_orderdate < DATE '1995-12-31'
GROUP BY 
    c.c_custkey, c.c_name
ORDER BY 
    revenue DESC
LIMIT 10;