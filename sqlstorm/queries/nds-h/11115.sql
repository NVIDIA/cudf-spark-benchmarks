SELECT 
    l_shipmode, 
    COUNT(*) AS count_orders, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue 
FROM 
    lineitem 
WHERE 
    l_shipdate BETWEEN DATE '1994-01-01' AND DATE '1995-12-31' 
GROUP BY 
    l_shipmode 
ORDER BY 
    total_revenue DESC;
