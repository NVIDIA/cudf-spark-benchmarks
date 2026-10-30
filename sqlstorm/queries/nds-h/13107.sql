SELECT 
    s_name, 
    SUM(ps_supplycost * ps_availqty) AS total_cost
FROM 
    supplier 
JOIN 
    partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey
GROUP BY 
    s_name
ORDER BY 
    total_cost DESC
LIMIT 10;
