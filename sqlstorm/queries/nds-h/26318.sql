SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    CONCAT('Manufacturer: ', p_mfgr) AS manufacturer_info,
    REPLACE(p_comment, 'old', 'new') AS updated_comment,
    LENGTH(p_name) AS name_length,
    LEFT(l_comment, 20) AS short_lineitem_comment,
    CASE 
        WHEN p_size > 10 THEN 'Large' 
        WHEN p_size BETWEEN 5 AND 10 THEN 'Medium' 
        ELSE 'Small' 
    END AS size_category
FROM 
    part
JOIN 
    partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN 
    lineitem ON partsupp.ps_partkey = lineitem.l_partkey
WHERE 
    LENGTH(p_comment) > 10 
AND 
    p_name LIKE 'A%'
ORDER BY 
    name_length DESC, p_retailprice ASC
LIMIT 50;
