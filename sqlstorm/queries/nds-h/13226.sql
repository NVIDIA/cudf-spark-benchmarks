SELECT 
    o.o_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
GROUP BY 
    o.o_orderkey
ORDER BY 
    revenue DESC
LIMIT 10;