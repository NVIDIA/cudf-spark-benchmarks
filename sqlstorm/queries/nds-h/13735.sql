SELECT 
    l_shipmode, 
    COUNT(*) AS count_order 
FROM 
    lineitem 
WHERE 
    l_shipdate >= '1997-01-01' 
    AND l_shipdate < '1998-01-01' 
GROUP BY 
    l_shipmode 
ORDER BY 
    count_order DESC;