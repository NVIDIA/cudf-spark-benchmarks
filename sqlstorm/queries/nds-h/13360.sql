SELECT 
    l_shipmode, 
    COUNT(DISTINCT o_orderkey) AS order_count, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    lineitem 
JOIN 
    orders ON l_orderkey = o_orderkey 
WHERE 
    l_shipdate >= DATE '1997-01-01' 
    AND l_shipdate < DATE '1997-12-31' 
GROUP BY 
    l_shipmode 
ORDER BY 
    revenue DESC;