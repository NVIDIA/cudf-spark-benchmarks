SELECT 
    l.l_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1995-01-01' AND 
    o.o_orderdate < '1996-01-01' AND 
    l.l_shipmode IN ('TRUCK', 'SHIP')
GROUP BY 
    l.l_orderkey
ORDER BY 
    revenue DESC
LIMIT 10;
