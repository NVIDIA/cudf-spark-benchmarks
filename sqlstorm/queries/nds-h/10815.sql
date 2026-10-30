SELECT 
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    O.o_orderdate
FROM 
    lineitem l
JOIN 
    orders O ON l.l_orderkey = O.o_orderkey
WHERE 
    O.o_orderdate >= '1996-01-01' AND O.o_orderdate < '1997-01-01'
GROUP BY 
    l_orderkey, O.o_orderdate
ORDER BY 
    revenue DESC
LIMIT 10;
