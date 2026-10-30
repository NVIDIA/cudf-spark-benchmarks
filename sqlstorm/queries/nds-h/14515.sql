SELECT 
    p_brand, 
    AVG(l_extendedprice * (1 - l_discount)) AS avg_price 
FROM 
    lineitem 
JOIN 
    partsupp ON lineitem.l_partkey = partsupp.ps_partkey 
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey 
GROUP BY 
    p_brand 
ORDER BY 
    avg_price DESC 
LIMIT 10;
