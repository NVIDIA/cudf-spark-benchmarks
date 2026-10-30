SELECT 
    p.p_partkey, 
    COUNT(ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_supplycost) AS total_supplycost, 
    AVG(ps.ps_availqty) AS avg_availqty 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
GROUP BY 
    p.p_partkey 
ORDER BY 
    total_supplycost DESC 
LIMIT 10;
