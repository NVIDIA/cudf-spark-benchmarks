SELECT 
    p.p_name, 
    SUM(line.l_quantity) AS total_quantity, 
    SUM(line.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    lineitem line ON p.p_partkey = line.l_partkey
GROUP BY 
    p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
