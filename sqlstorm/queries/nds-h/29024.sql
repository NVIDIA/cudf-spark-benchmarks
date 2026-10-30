SELECT 
    CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name) AS part_supplier_info,
    LENGTH(p.p_comment) AS comment_length,
    UPPER(s.s_name) AS supplier_name_upper,
    SUBSTRING(p.p_mfgr, 1, 3) AS manufacturer_prefix,
    REPLACE(REPLACE(s.s_address, 'Street', 'St'), 'Road', 'Rd') AS formatted_address,
    CASE 
        WHEN p.p_retailprice > 100.00 THEN 'High Price'
        WHEN p.p_retailprice BETWEEN 50.00 AND 100.00 THEN 'Medium Price'
        ELSE 'Low Price' 
    END AS price_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size > 10
AND 
    s.s_acctbal >= 50000
ORDER BY 
    comment_length DESC, 
    supplier_name_upper ASC
LIMIT 50;
