SELECT 
    l.l_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate > '1996-01-01' 
    AND l.l_shipdate < '1996-12-31'
GROUP BY 
    l.l_orderkey
ORDER BY 
    total_revenue DESC
LIMIT 100;