SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ps.ps_supplycost) AS total_supplycost, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_supplycost DESC
LIMIT 10;
