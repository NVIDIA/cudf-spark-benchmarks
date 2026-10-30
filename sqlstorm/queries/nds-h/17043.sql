SELECT 
    p.p_name, 
    s.s_name, 
    PS.ps_supplycost
FROM 
    part p
JOIN 
    partsupp PS ON p.p_partkey = PS.ps_partkey
JOIN 
    supplier s ON PS.ps_suppkey = s.s_suppkey
WHERE 
    PS.ps_availqty > 0
ORDER BY 
    p.p_name;
