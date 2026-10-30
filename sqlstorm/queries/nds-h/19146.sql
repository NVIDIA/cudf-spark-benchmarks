SELECT 
    p_name, 
    s_name, 
    ps_supplycost 
FROM 
    part 
JOIN 
    partsupp ON part.p_partkey = partsupp.ps_partkey 
JOIN 
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey 
WHERE 
    ps_supplycost > 100.00 
ORDER BY 
    ps_supplycost DESC 
LIMIT 10;
