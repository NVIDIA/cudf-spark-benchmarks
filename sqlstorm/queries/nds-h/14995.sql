SELECT 
    l.l_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales 
FROM 
    lineitem l 
INNER JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31' 
GROUP BY 
    l.l_orderkey 
ORDER BY 
    sales DESC 
LIMIT 10;