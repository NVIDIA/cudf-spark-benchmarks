SELECT 
    p.p_name,
    s.s_name,
    n.n_name,
    CONCAT('Supplier ', s.s_name, ' from ', n.n_name, ' supplies part ', p.p_name) AS supply_description,
    LENGTH(CONCAT('Supplier ', s.s_name, ' from ', n.n_name, ' supplies part ', p.p_name)) AS description_length
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size BETWEEN 10 AND 20
AND 
    s.s_acctbal > 1000.00
ORDER BY 
    description_length DESC
LIMIT 10;
