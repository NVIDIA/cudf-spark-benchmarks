SELECT 
    p.p_name, 
    s.s_name, 
    concat('Supplier: ', s.s_name, ' supplies ', p.p_name, ' which costs $', p.p_retailprice) AS supply_info,
    CASE 
        WHEN LENGTH(p.p_comment) > 20 THEN CONCAT(SUBSTRING(p.p_comment, 1, 20), '...') 
        ELSE p.p_comment 
    END AS short_comment,
    REPLACE(REPLACE(p.p_type, ' ', '_'), '-', '_') AS sanitized_type
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND s.s_acctbal BETWEEN 1000 AND 5000
ORDER BY 
    p.p_name ASC, 
    s.s_name DESC
LIMIT 100;
