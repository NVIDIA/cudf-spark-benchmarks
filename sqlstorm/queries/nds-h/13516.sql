SELECT 
    p.p_brand, 
    AVG(ps.ps_supplycost) AS avg_supplycost, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_brand
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    avg_supplycost DESC
LIMIT 10;
