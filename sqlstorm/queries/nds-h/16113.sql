SELECT 
    p_name, 
    SUM(l_quantity) AS total_quantity, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    lineitem 
JOIN 
    part ON lineitem.l_partkey = part.p_partkey
GROUP BY 
    p_name
ORDER BY 
    revenue DESC
LIMIT 10;
