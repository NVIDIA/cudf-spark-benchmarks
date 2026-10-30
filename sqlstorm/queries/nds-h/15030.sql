SELECT 
    p_name, 
    SUM(ps_supplycost * ps_availqty) AS total_cost
FROM 
    partsupp
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey
GROUP BY 
    p_name
ORDER BY 
    total_cost DESC
LIMIT 10;
