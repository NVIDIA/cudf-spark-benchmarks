SELECT 
    p.p_name,
    LENGTH(p.p_name) AS name_length,
    UPPER(p.p_name) AS upper_name,
    LOWER(p.p_name) AS lower_name,
    REPLACE(p.p_comment, 's', '$') AS modified_comment,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS manufacturer_brand,
    CASE 
        WHEN p.p_size < 10 THEN 'Small' 
        WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium' 
        ELSE 'Large' 
    END AS size_category,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    r.r_name AS region_name
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
    p.p_retailprice > 100.00
    AND p.p_comment LIKE '%fragile%'
GROUP BY 
    p.p_name, p.p_comment, p.p_mfgr, p.p_brand, p.p_size, r.r_name
ORDER BY 
    name_length DESC, supplier_count DESC;
