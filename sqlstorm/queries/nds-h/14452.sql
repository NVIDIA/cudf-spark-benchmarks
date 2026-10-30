SELECT 
    l_shipmode,
    COUNT(*) AS shipment_count,
    SUM(l_extendedprice) AS total_revenue,
    AVG(l_discount) AS avg_discount
FROM 
    lineitem
WHERE 
    l_shipdate >= '1995-01-01' AND l_shipdate < '1996-01-01'
GROUP BY 
    l_shipmode
ORDER BY 
    total_revenue DESC;
