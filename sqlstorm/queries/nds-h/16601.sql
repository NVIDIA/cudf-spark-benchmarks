SELECT 
    p.p_name, 
    SUM(ps.ps_availqty) AS total_availqty, 
    AVG(l.l_extendedprice) AS avg_extendedprice
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    p.p_name
ORDER BY 
    total_availqty DESC
LIMIT 10;
