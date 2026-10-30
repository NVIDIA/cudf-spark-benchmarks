SELECT 
    l.l_shipdate, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= DATE '1995-01-01' 
    AND l.l_shipdate < DATE '1996-01-01'
    AND o.o_orderstatus = 'F'
GROUP BY 
    l.l_shipdate
ORDER BY 
    l.l_shipdate;
