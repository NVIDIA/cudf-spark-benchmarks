
SELECT 
    p.p_name,
    CONCAT('Brand: ', p.p_brand, ', Manufacturer: ', p.p_mfgr, ', Size: ', CAST(p.p_size AS STRING), ', Price: $', CAST(p.p_retailprice AS STRING), ', Comment: ', p.p_comment) AS details,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE 
        WHEN s.s_acctbal > 1000 THEN 1 
        ELSE 0 
    END) AS high_balance_suppliers,
    LOWER(SUBSTRING(p.p_name, 1, POSITION(' ' IN p.p_name || ' ') - 1)) AS first_word_lowercase,
    LENGTH(p.p_name) AS name_length
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 100
GROUP BY 
    p.p_name, p.p_brand, p.p_mfgr, p.p_size, p.p_retailprice, p.p_comment, name_length
ORDER BY 
    name_length DESC, supplier_count ASC;
