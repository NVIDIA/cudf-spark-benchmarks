SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_suppkey, 
    s.s_name, 
    SUM(ps.ps_availqty) as total_availqty,
    SUM(ps.ps_supplycost) as total_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_suppkey, 
    s.s_name
ORDER BY 
    total_availqty DESC
LIMIT 100;
