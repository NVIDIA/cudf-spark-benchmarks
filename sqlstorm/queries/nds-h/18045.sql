SELECT 
    p_brand, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    lineitem 
JOIN 
    partsupp ON lineitem.l_partkey = partsupp.ps_partkey 
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey 
WHERE 
    l_shipdate >= '1997-01-01' 
    AND l_shipdate < '1997-12-31'
GROUP BY 
    p_brand
ORDER BY 
    revenue DESC;