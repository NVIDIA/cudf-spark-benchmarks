SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(li.l_quantity) AS total_quantity, 
    SUM(li.l_extendedprice) AS total_extended_price
FROM 
    part p
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_extended_price DESC
LIMIT 10;
