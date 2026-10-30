SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_extended_price
FROM 
    lineitem l 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    p.p_name
ORDER BY 
    total_quantity DESC
LIMIT 10;
