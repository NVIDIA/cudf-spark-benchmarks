SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    CONCAT('Manufactured by: ', p.p_mfgr, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type, 
           ' | Size: ', p.p_size, ' | Container: ', p.p_container, 
           ' | Retail Price: $', CAST(p.p_retailprice AS STRING), 
           ' | Comment: ', p.p_comment) AS part_description
FROM 
    part p
WHERE 
    p.p_retailprice > 100.00 
    AND p.p_comment LIKE '%special%'
ORDER BY 
    p.p_name ASC
LIMIT 10;
