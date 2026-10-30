SELECT 
    p.p_brand, 
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_brand
ORDER BY 
    avg_price DESC
LIMIT 10;
