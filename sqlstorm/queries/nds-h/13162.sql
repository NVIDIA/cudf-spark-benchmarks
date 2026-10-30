SELECT 
    l_shipmode, 
    COUNT(*) AS ship_count, 
    SUM(l_quantity) AS total_quantity, 
    AVG(l_extendedprice) AS avg_extended_price
FROM 
    lineitem
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    l_shipmode
ORDER BY 
    ship_count DESC;