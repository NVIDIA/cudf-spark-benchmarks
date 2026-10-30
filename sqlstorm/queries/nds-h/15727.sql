SELECT 
    p.p_brand, 
    AVG(ps.ps_supplycost) AS avg_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p.p_brand
ORDER BY 
    avg_supplycost DESC
LIMIT 10;
