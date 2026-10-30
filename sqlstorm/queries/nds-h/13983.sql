SELECT 
    ps.ps_partkey, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    ps.ps_partkey
ORDER BY 
    total_cost DESC
LIMIT 10;
