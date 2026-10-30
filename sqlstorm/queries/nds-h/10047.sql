SELECT 
    l_suppkey,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    COUNT(*) AS total_orders
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1998-01-01'
GROUP BY 
    l_suppkey
ORDER BY 
    total_revenue DESC
LIMIT 10;