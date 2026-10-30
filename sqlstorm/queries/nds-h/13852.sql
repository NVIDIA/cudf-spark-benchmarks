SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderpriority
FROM 
    orders AS o
JOIN 
    lineitem AS l ON o.o_orderkey = l.l_orderkey
WHERE 
    o_orderdate >= DATE '1997-01-01' AND o_orderdate < DATE '1997-02-01'
GROUP BY 
    o_orderpriority
ORDER BY 
    total_revenue DESC;