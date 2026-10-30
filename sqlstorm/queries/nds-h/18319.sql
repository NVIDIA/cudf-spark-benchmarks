SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
FROM 
    lineitem l
JOIN 
    part p ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_name
ORDER BY 
    total_sales DESC
LIMIT 10;
