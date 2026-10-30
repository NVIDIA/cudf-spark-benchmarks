SELECT 
    p.p_name,
    ps.ps_availqty,
    ps.ps_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
WHERE 
    ps.ps_availqty > 100
ORDER BY 
    ps.ps_supplycost DESC;
