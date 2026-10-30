SELECT 
    l_shipmode, 
    COUNT(*) AS delivery_count, 
    SUM(l_extendedprice) AS total_revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= '1997-01-01' 
    AND l_shipdate < '1998-01-01'
GROUP BY 
    l_shipmode
ORDER BY 
    total_revenue DESC;