SELECT 
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    o.o_orderpriority
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
GROUP BY 
    l.l_orderkey, o.o_orderpriority
ORDER BY 
    total_revenue DESC
LIMIT 10;