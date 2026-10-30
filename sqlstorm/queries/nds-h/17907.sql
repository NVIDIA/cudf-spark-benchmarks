SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(lp.l_quantity) AS total_quantity, 
    SUM(lp.l_extendedprice) AS total_extended_price
FROM 
    part p
JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey
GROUP BY 
    p.p_partkey, 
    p.p_name
ORDER BY 
    total_quantity DESC
LIMIT 10;
