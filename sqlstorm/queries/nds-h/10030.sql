SELECT 
    c.c_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY 
    c.c_name, o.o_orderkey
ORDER BY 
    revenue DESC
LIMIT 100;