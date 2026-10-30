SELECT 
    p.p_brand, 
    p.p_type, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    total_cost DESC
LIMIT 10;
