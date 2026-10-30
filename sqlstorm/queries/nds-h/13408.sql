SELECT 
    ps.ps_partkey,
    SUM(ps.ps_availqty) AS total_availqty,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    COUNT(s.s_suppkey) AS supplier_count
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    ps.ps_partkey
ORDER BY 
    total_availqty DESC
LIMIT 10;
