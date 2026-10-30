SELECT 
    p_brand,
    COUNT(DISTINCT ps_suppkey) AS supplier_count,
    AVG(ps_supplycost) AS avg_supplycost,
    SUM(ps_availqty) AS total_available_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p_brand
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
