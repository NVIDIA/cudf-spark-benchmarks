SELECT 
    CONCAT('Part: ', p_name, ' | ', 'Manufacturer: ', p_mfgr, ' | ', 'Brand: ', p_brand, 
           ' | ', 'Type: ', p_type, ' | ', 'Size: ', CAST(p_size AS STRING), 
           ' | ', 'Retail Price: ', CAST(p_retailprice AS STRING), 
           ' | ', 'Comment: ', p_comment) AS part_details,
    TRIM(n_name) AS nation_name,
    COUNT(DISTINCT s_suppkey) AS supplier_count
FROM 
    part 
JOIN 
    partsupp ON part.p_partkey = partsupp.ps_partkey 
JOIN 
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey 
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey 
WHERE 
    p_name LIKE '%Steel%' 
    AND p_retailprice > 100.00 
GROUP BY 
    p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_retailprice, p_comment, n_name 
HAVING 
    COUNT(DISTINCT s_suppkey) > 5 
ORDER BY 
    p_retailprice DESC;
