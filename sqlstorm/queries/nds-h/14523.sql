SELECT 
    l.l_shipmode, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    lineitem l
WHERE 
    l.l_shipdate >= DATE '1996-01-01' AND 
    l.l_shipdate <= DATE '1996-12-31'
GROUP BY 
    l.l_shipmode
ORDER BY 
    total_revenue DESC;