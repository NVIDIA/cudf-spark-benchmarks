
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    REGEXP_REPLACE(p.p_mfgr, '([a-z])([A-Z])', '\\1 \\2') AS formatted_mfgr,
    CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand) AS part_brand_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    LENGTH(p.p_name) > 5 
    AND p.p_retailprice > 50.00 
    AND POSITION('Quality' IN p.p_comment) > 0
GROUP BY 
    p.p_name, p.p_mfgr, p.p_brand, p.p_comment
ORDER BY 
    supplier_count DESC, total_available_quantity ASC
LIMIT 100;
