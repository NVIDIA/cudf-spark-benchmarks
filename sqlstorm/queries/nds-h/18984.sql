SELECT 
    p.p_name, 
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue 
FROM 
    part p 
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey 
WHERE 
    ls.l_shipdate >= '1996-01-01' AND ls.l_shipdate < '1997-01-01' 
GROUP BY 
    p.p_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;