SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1997-01-01'
    AND l_returnflag = 'N'
GROUP BY 
    l_orderkey
ORDER BY 
    total_revenue DESC
LIMIT 10;
