SELECT 
    s_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    supplier 
JOIN 
    partsupp ON s_suppkey = ps_suppkey 
JOIN 
    part ON ps_partkey = p_partkey 
JOIN 
    lineitem ON l_partkey = p_partkey 
GROUP BY 
    s_name 
ORDER BY 
    revenue DESC 
LIMIT 10;