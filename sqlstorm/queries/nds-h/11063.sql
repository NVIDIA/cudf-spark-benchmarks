SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue, 
    o_orderdate
FROM 
    lineitem
JOIN 
    orders ON l_orderkey = o_orderkey
WHERE 
    o_orderdate >= DATE '1997-01-01' AND o_orderdate < DATE '1997-02-01'
GROUP BY 
    o_orderdate
ORDER BY 
    o_orderdate;