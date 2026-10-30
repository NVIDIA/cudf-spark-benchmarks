SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_revenue 
FROM 
    lineitem l 
JOIN 
    part p ON l.l_partkey = p.p_partkey 
GROUP BY 
    p.p_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
