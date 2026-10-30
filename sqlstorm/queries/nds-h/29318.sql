SELECT 
    CONCAT('Supplier: ', s_name, ' | Part: ', p_name, ' | Type: ', p_type, ' | Size: ', p_size, ' | Comment: ', p_comment) AS item_details,
    REPLACE(r_name, 'Region', 'Area') AS modified_region_name,
    LENGTH(p_comment) AS comment_length,
    TRIM(LEADING 'A' FROM s_comment) AS modified_supplier_comment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    comment_length DESC
LIMIT 100;
