SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name, 
    CONCAT('Manufacturer: ', p_mfgr) AS manufacturer_info, 
    LOWER(p_type) AS lower_type, 
    LENGTH(p_comment) AS comment_length, 
    CONCAT(n_name, ' (Region: ', r_name, ')') AS nation_region 
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey 
JOIN 
    supplier ON ps_suppkey = s_suppkey 
JOIN 
    nation ON s_nationkey = n_nationkey 
JOIN 
    region ON n_regionkey = r_regionkey 
WHERE 
    p_retailprice > 100 
ORDER BY 
    comment_length DESC 
LIMIT 50;
