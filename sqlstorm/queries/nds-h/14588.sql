SELECT 
    l_shipmode, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    lineitem 
WHERE 
    l_shipdate >= DATE '1997-01-01' 
    AND l_shipdate < DATE '1997-01-31' 
GROUP BY 
    l_shipmode 
ORDER BY 
    revenue DESC;