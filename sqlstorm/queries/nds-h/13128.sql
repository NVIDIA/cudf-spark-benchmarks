SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_supplycost DESC
LIMIT 10;
