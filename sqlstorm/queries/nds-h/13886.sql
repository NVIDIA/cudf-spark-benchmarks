SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    ps.ps_availqty, 
    ps.ps_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    ps.ps_availqty DESC 
LIMIT 100;
