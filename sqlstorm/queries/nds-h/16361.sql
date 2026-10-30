SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue 
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
GROUP BY 
    p.p_name 
ORDER BY 
    revenue DESC 
LIMIT 10;
