SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ps.ps_availqty) AS total_availqty, 
    AVG(ps.ps_supplycost) AS avg_supplycost,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
GROUP BY 
    p.p_partkey, 
    p.p_name 
ORDER BY 
    total_availqty DESC 
LIMIT 100;
