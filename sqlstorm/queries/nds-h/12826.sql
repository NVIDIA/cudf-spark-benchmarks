SELECT 
    p.p_name, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p.p_name
ORDER BY 
    total_cost DESC
LIMIT 10;
