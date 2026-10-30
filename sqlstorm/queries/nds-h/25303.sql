
SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Price: ', p.p_retailprice) AS supplier_part_info,
    LENGTH(CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Price: ', p.p_retailprice)) AS string_length,
    SUBSTR(p.p_comment, 1, 20) AS short_comment,
    INITCAP(p.p_type) AS capitalized_type,
    COUNT(*) AS supply_count
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_name LIKE '%Co%' 
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    s.s_name, p.p_name, p.p_retailprice, p.p_comment, p.p_type
ORDER BY 
    string_length DESC
LIMIT 10;
