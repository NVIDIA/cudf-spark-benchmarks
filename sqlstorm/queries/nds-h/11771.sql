SELECT 
    ps.ps_partkey, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_availqty, 
    AVG(ps.ps_supplycost) AS avg_supplycost
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    ps.ps_partkey
ORDER BY 
    total_availqty DESC
LIMIT 100;
