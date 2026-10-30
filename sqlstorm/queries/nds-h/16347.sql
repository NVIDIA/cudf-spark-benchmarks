SELECT 
    p_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue 
FROM 
    part 
JOIN 
    lineitem ON part.p_partkey = lineitem.l_partkey 
WHERE 
    lineitem.l_shipdate >= DATE '1995-01-01' 
    AND lineitem.l_shipdate < DATE '1996-01-01' 
GROUP BY 
    p_name 
ORDER BY 
    revenue DESC 
LIMIT 10;
