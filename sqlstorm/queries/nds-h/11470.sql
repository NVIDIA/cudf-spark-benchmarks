SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderpriority 
FROM 
    orders o 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
WHERE 
    l_shipdate >= '1995-01-01' AND l_shipdate < '1996-01-01' 
GROUP BY 
    o_orderpriority 
ORDER BY 
    total_revenue DESC;