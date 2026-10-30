SELECT 
    l.l_shipmode, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales
FROM 
    lineitem l
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-01-31'
GROUP BY 
    l.l_shipmode
ORDER BY 
    sales DESC;