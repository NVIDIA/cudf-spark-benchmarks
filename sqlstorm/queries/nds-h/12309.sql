SELECT 
    p.p_brand,
    p.p_type,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    SUM(l.l_quantity) AS total_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey
GROUP BY 
    p.p_brand, p.p_type
ORDER BY 
    avg_supplycost DESC
LIMIT 10;
