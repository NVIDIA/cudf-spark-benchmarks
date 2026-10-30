SELECT 
    l.l_shipmode, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    o.o_orderdate 
FROM 
    lineitem l 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND 
    o.o_orderdate < DATE '1998-01-01' 
GROUP BY 
    l.l_shipmode, o.o_orderdate 
ORDER BY 
    revenue DESC;
