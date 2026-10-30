SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue, 
    o_orderstatus 
FROM 
    lineitem 
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey 
WHERE 
    l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01' 
GROUP BY 
    o_orderstatus 
ORDER BY 
    revenue DESC;