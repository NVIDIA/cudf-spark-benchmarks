SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_container,
    p.p_retailprice,
    p.p_comment,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS product_info,
    CASE 
        WHEN p.p_size < 10 THEN 'Small'
        WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
        ELSE 'Large'
    END AS size_category,
    REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS clean_comment
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
    r.r_name = 'ASIA' 
    AND LENGTH(p.p_comment) > 10
ORDER BY 
    p.p_retailprice DESC
LIMIT 100;
