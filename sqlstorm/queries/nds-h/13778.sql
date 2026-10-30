SELECT 
    l_shipmode, 
    COUNT(*) AS ship_count, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    lineitem 
WHERE 
    l_shipdate >= '1995-01-01' AND l_shipdate < '1996-01-01' 
GROUP BY 
    l_shipmode 
ORDER BY 
    ship_count DESC;
