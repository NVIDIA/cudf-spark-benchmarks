SELECT 
    p.p_name, 
    SUM(l.l_extendedprice) AS total_revenue 
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
WHERE 
    l.l_returnflag = 'N' 
GROUP BY 
    p.p_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
