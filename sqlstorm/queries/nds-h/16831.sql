SELECT 
    p.p_name, 
    SUM(ls.l_quantity) AS total_quantity, 
    SUM(ls.l_extendedprice) AS total_revenue 
FROM 
    part p 
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey 
GROUP BY 
    p.p_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
