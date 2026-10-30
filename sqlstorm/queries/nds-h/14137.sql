SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '1997-01-01'
    AND l_shipdate < DATE '1997-12-31'
GROUP BY 
    l_returnflag, l_linestatus
ORDER BY 
    l_returnflag, l_linestatus;