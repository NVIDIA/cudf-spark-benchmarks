SELECT 
    p_type, 
    COUNT(*) AS part_count, 
    AVG(ps_supplycost) AS avg_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p_type
ORDER BY 
    avg_supplycost DESC
LIMIT 10;
