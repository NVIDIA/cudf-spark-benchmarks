SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Price: $', CAST(p.p_retailprice AS VARCHAR(10)), 
           ', Comment: ', p.p_comment) AS description
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND s.s_acctbal > 1000.00
    AND p.p_mfgr LIKE 'Manufacturer%'
ORDER BY 
    s.s_name DESC, p.p_name ASC
LIMIT 50;
