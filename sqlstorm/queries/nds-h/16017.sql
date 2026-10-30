SELECT 
    p.p_partkey, 
    p.p_name, 
    ps.ps_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
WHERE 
    ps.ps_availqty > 0
ORDER BY 
    ps.ps_supplycost DESC
LIMIT 10;
