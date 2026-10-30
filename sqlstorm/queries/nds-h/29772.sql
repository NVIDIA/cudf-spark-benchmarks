SELECT 
    p.p_partkey,
    LENGTH(p.p_name) AS name_length,
    UPPER(SUBSTRING(p.p_comment, 1, 20)) AS comment_excerpt,
    REGEXP_REPLACE(p.p_mfgr, '[^A-Za-z]', '') AS cleaned_mfgr,
    CONCAT('Brand: ', p.p_brand, ' | Type: ', p.p_type) AS brand_type,
    REPLACE(p.p_container, 'Box', 'Container') AS modified_container,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_avail_qty
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
WHERE 
    p.p_size > 10
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_container, p.p_comment
ORDER BY 
    total_avail_qty DESC
LIMIT 100;
