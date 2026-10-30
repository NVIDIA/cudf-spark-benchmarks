SELECT 
    p.p_mfgr, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_mfgr
ORDER BY 
    total_supplycost DESC
LIMIT 10;
