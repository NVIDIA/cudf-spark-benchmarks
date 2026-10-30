SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    s.s_name AS supplier_name, 
    ps.ps_supplycost, 
    ps.ps_availqty 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    ps.ps_supplycost < 100 
ORDER BY 
    ps.ps_supplycost DESC 
LIMIT 100;
