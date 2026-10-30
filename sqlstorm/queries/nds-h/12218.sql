SELECT 
    L.l_orderkey, 
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS revenue, 
    O.o_orderdate
FROM 
    lineitem L
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
WHERE 
    O.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    L.l_orderkey, O.o_orderdate
ORDER BY 
    revenue DESC
LIMIT 100;