SELECT 
    CONCAT(p.p_name, ' (', s.s_name, ')') AS part_supplier_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    REPLACE(p.p_mfgr, 'Manufacturer', 'Mfg') AS manufacturer,
    LENGTH(p.p_type) AS type_length,
    CASE 
        WHEN p.p_retailprice > 100 THEN 'Expensive'
        WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'Cheap'
    END AS price_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size > 10)
ORDER BY 
    type_length DESC, price_category ASC;
