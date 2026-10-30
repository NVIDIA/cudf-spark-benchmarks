SELECT 
    l_shipmode,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1997-12-31'
GROUP BY 
    l_shipmode
ORDER BY 
    total_revenue DESC;