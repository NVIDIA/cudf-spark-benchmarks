SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name, 
    CONCAT('Manufacturer: ', p_mfgr, ', Brand: ', p_brand) AS mfgr_brand_info,
    LENGTH(p_comment) AS comment_length,
    REGEXP_REPLACE(p_comment, 'badword', '****') AS filtered_comment,
    (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supplier_count
FROM 
    part p
WHERE 
    p_size BETWEEN 10 AND 20 
    AND p_retailprice > 50.00
    AND p_type LIKE '%steel%'
ORDER BY 
    comment_length DESC
LIMIT 100;
