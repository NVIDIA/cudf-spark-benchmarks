
SELECT 
    p.p_partkey,
    TRIM(UPPER(p.p_name)) AS processed_name,
    CONCAT(p.p_brand, ' - ', p.p_mfgr) AS brand_mfgr,
    REPLACE(p.p_comment, 'Quality', 'Excellence') AS modified_comment,
    SUBSTRING(p.p_type, 1, 10) AS short_type,
    CASE 
        WHEN p.p_retailprice > 500 THEN 'High'
        WHEN p.p_retailprice BETWEEN 200 AND 500 THEN 'Medium'
        ELSE 'Low'
    END AS price_category,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    s.s_acctbal > 1000 
    AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 50)
GROUP BY 
    p.p_partkey, 
    processed_name, 
    p.p_brand, 
    p.p_mfgr, 
    modified_comment, 
    p.p_retailprice, 
    short_type, 
    price_category
ORDER BY 
    processed_name, 
    price_category DESC
LIMIT 50;
