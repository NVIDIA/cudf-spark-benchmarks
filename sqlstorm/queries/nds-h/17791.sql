SELECT 
    p_name, 
    SUM(ps_supplycost * ps_availqty) AS total_value
FROM 
    part 
JOIN 
    partsupp ON part.p_partkey = partsupp.ps_partkey
GROUP BY 
    p_name 
ORDER BY 
    total_value DESC 
LIMIT 10;
