SELECT 
    l_shipmode, 
    COUNT(*) AS shipment_count, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    lineitem 
WHERE 
    l_shipdate >= DATE '1995-01-01' AND l_shipdate < DATE '1996-01-01' 
GROUP BY 
    l_shipmode 
ORDER BY 
    shipment_count DESC;
