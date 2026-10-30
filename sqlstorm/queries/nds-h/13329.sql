SELECT 
    l_shipmode, 
    COUNT(DISTINCT o_orderkey) AS total_orders, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    lineitem
JOIN 
    orders ON l_orderkey = o_orderkey
WHERE 
    l_shipdate >= '1997-01-01' AND l_shipdate < '1997-12-31'
GROUP BY 
    l_shipmode
ORDER BY 
    total_orders DESC;