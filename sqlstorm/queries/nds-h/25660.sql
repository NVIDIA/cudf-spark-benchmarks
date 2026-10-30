SELECT 
    p.p_name AS part_name,
    LENGTH(p.p_name) AS name_length,
    SUBSTR(p.p_comment, 1, 15) AS short_comment,
    REPLACE(p.p_brand, 'Brand', 'Replaced') AS modified_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
WHERE 
    p.p_size > 10 
    AND p.p_retailprice BETWEEN 20.00 AND 100.00
GROUP BY 
    p.p_name, p.p_brand, p.p_comment
ORDER BY 
    name_length DESC, total_available_quantity DESC
LIMIT 
    10;
