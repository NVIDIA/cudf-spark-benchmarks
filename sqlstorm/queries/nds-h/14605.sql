SELECT 
    l.l_suppkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
GROUP BY 
    l.l_suppkey
ORDER BY 
    total_revenue DESC
LIMIT 10;